import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Play, Tv, Film, Heart, History, Radio, Clapperboard, Sparkles, ListPlus, Info, Star, TrendingUp, Layers, Plus, Check } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { MediaRow } from '../components/media/MediaRow';
import { PosterCard } from '../components/media/PosterCard';
import { SeriesItem, VodItem } from '../types';

const ROW_LIMIT = 20;

type Featured = VodItem | SeriesItem;
const isVod = (x: Featured): x is VodItem => 'streamUrl' in x;

function topCategories<T extends { category: string }>(items: T[], n: number): string[] {
  const counts = new Map<string, number>();
  for (const it of items) counts.set(it.category, (counts.get(it.category) ?? 0) + 1);
  return Array.from(counts.entries())
    .filter(([, c]) => c >= 4)
    .sort((a, b) => b[1] - a[1])
    .slice(0, n)
    .map(([k]) => k);
}

export const HomeView: React.FC = () => {
  const {
    isHydrated,
    playlists,
    filteredChannels,
    favorites,
    history,
    vodItems,
    seriesItems,
    continueWatchingItems,
    getProgressFraction,
    resumeHistoryItem,
    playChannel,
    playVod,
    setActiveTab,
    setSelectedVodModal,
    setSelectedSeriesModal,
    enrichArtwork,
    loadDemoContent,
    syncStatus,
    myList,
    toggleMyList,
    isInMyList,
    getResumeSeconds,
  } = useApp();

  const rows = useMemo(() => {
    const recentVod = [...vodItems].filter((v) => v.addedAt).sort((a, b) => (b.addedAt ?? 0) - (a.addedAt ?? 0)).slice(0, ROW_LIMIT);
    const topRated = [...vodItems].filter((v) => v.rating >= 7).sort((a, b) => b.rating - a.rating).slice(0, ROW_LIMIT);
    const recentSeries = [...seriesItems].sort((a, b) => (b.addedAt ?? 0) - (a.addedAt ?? 0)).slice(0, ROW_LIMIT);
    const vodCats = topCategories(vodItems, 6).map((cat) => ({ cat, items: vodItems.filter((v) => v.category === cat).slice(0, ROW_LIMIT) }));
    const favSet = new Set(favorites);
    const favChannels = filteredChannels.filter((c) => favSet.has(c.id)).slice(0, ROW_LIMIT);
    const byId = new Map(filteredChannels.map((c) => [c.id, c]));
    const recentChannels = history
      .filter((h) => h.contentType === 'channel')
      .map((h) => byId.get(h.contentId))
      .filter((c): c is NonNullable<typeof c> => !!c)
      .slice(0, 8);
    const hero: VodItem | SeriesItem | undefined =
      vodItems.find((v) => v.backdropUrl && v.rating >= 7) || vodItems.find((v) => v.backdropUrl) || seriesItems.find((s) => s.backdropUrl) || vodItems[0];
    const vodById = new Map(vodItems.map((v) => [v.id, v]));
    const serById = new Map(seriesItems.map((x) => [x.id, x]));
    const myListItems = myList
      .map((id) => (vodById.get(id) as Featured | undefined) ?? (serById.get(id) as Featured | undefined))
      .filter((x): x is Featured => !!x)
      .slice(0, ROW_LIMIT);
    return { recentVod, topRated, recentSeries, vodCats, favChannels, recentChannels, hero, myListItems };
  }, [vodItems, seriesItems, filteredChannels, favorites, history, myList]);

  // Billboard: follows the focused title like streaming apps on TV; rotates when idle.
  const heroCandidates = useMemo(() => {
    const withArt = [...vodItems.filter((v) => v.backdropUrl), ...seriesItems.filter((s) => s.backdropUrl)]
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 6) as Featured[];
    return withArt.length ? withArt : rows.hero ? [rows.hero as Featured] : [];
  }, [vodItems, seriesItems, rows.hero]);
  const [focused, setFocused] = useState<Featured | null>(null);
  const [rotateIdx, setRotateIdx] = useState(0);
  const focusTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const featureItem = (item: Featured) => {
    if (focusTimer.current) clearTimeout(focusTimer.current);
    // Short delay so scrolling quickly through a row does not flash every backdrop.
    focusTimer.current = setTimeout(() => setFocused(item), 180);
  };
  useEffect(() => {
    if (focused || heroCandidates.length < 2) return;
    const t = setInterval(() => setRotateIdx((i) => (i + 1) % heroCandidates.length), 9000);
    return () => clearInterval(t);
  }, [focused, heroCandidates.length]);
  useEffect(() => () => {
    if (focusTimer.current) clearTimeout(focusTimer.current);
  }, []);
  const featured: Featured | undefined = focused ?? heroCandidates[rotateIdx % Math.max(1, heroCandidates.length)];
  useEffect(() => {
    if (featured) enrichArtwork(isVod(featured) ? 'vod' : 'series', featured.id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [featured?.id]);

  const openVod = (v: VodItem) => setSelectedVodModal(v);
  const openSeries = (s: SeriesItem) => setSelectedSeriesModal(s);

  if (!isHydrated) {
    return (
      <div className="px-6 md:px-12 py-8 space-y-8 animate-pulse" aria-label="Carregando sua biblioteca">
        <div className="h-[42vh] rounded-3xl bg-[#16162A]" />
        {[0, 1].map((r) => (
          <div key={r} className="space-y-3">
            <div className="h-4 w-48 rounded bg-[#16162A]" />
            <div className="flex gap-4 overflow-hidden">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="w-36 md:w-40 aspect-[2/3] shrink-0 rounded-2xl bg-[#16162A]" />
              ))}
            </div>
          </div>
        ))}
      </div>
    );
  }

  const isEmpty = playlists.length === 0 || (filteredChannels.length === 0 && vodItems.length === 0 && seriesItems.length === 0);

  if (isEmpty) {
    return (
      <div className="px-6 md:px-12 py-10 max-w-4xl mx-auto">
        <div className="rounded-3xl bg-[#16162A] border border-[#6B4FE0]/40 p-8 md:p-12 space-y-6 shadow-2xl">
          <div className="flex items-center gap-3">
            <Sparkles className="w-7 h-7 text-[#1FCFAE]" />
            <h1 className="text-2xl md:text-4xl font-extrabold text-white">Bem-vindo ao Nebula</h1>
          </div>
          <p className="text-sm md:text-base text-[#A8A6C0] leading-relaxed">
            O Nebula é um <strong className="text-white">player</strong>: ele organiza e reproduz as listas que você já possui
            (M3U/M3U8 ou login Xtream Codes do seu provedor). Canais ao vivo, filmes e séries aparecem aqui assim que você adicionar
            uma lista.
          </p>
          {syncStatus && (
            <div className="p-3 rounded-xl bg-[#6B4FE0]/20 border border-[#6B4FE0]/40 text-xs text-white">{syncStatus.step}</div>
          )}
          <div className="flex flex-wrap gap-3">
            <button
              autoFocus
              onClick={() => setActiveTab('playlists')}
              data-tv-title="Adicionar minha lista"
              className="tv-card px-6 py-3.5 rounded-2xl bg-[#6B4FE0] text-white font-bold text-sm flex items-center gap-2 cursor-pointer focus:outline-none"
            >
              <ListPlus className="w-5 h-5" /> Adicionar minha lista
            </button>
            <button
              onClick={loadDemoContent}
              data-tv-title="Explorar com conteúdo de demonstração"
              className="tv-card px-6 py-3.5 rounded-2xl bg-white/10 text-white font-semibold text-sm flex items-center gap-2 cursor-pointer focus:outline-none"
            >
              <Play className="w-5 h-5" /> Ver demonstração
            </button>
          </div>
          <p className="text-[11px] text-[#A8A6C0]/80 flex items-start gap-2">
            <Info className="w-4 h-4 shrink-0" />
            O Nebula não fornece, vende nem hospeda canais ou filmes. Use apenas listas e conteúdos que você tem direito de acessar.
          </p>
        </div>
      </div>
    );
  }

  const heroChannel = filteredChannels[0];

  return (
    <div className="relative px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-9 select-none">
      {/* Backdrop that follows focus (stays put while rows scroll over it) */}
      {featured && (featured.backdropUrl || featured.posterUrl) && (
        <div className="sticky top-0 h-0 z-0 pointer-events-none" aria-hidden>
          <div className="absolute -top-8 -left-6 md:-left-12 w-[calc(100%+3rem)] md:w-[calc(100%+6rem)] h-[78vh] overflow-hidden">
            <img
              key={featured.id}
              src={featured.backdropUrl || featured.posterUrl}
              alt=""
              onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
              className="absolute right-0 top-0 h-full w-full md:w-[72%] object-cover opacity-60 animate-[fadeIn_600ms_ease]"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-[#07070F] via-[#07070F]/80 to-transparent" />
            <div className="absolute inset-0 bg-gradient-to-t from-[#07070F] via-[#07070F]/30 to-transparent" />
          </div>
        </div>
      )}

      {/* Billboard */}
      {featured ? (
        <section className="relative z-10 min-h-[46vh] flex flex-col justify-end max-w-3xl space-y-4 pt-6">
          <span className="w-fit px-3 py-1 rounded-lg bg-[#FF6F91]/20 text-[#FF6F91] font-bold text-xs uppercase tracking-wider border border-[#FF6F91]/40">
            {isVod(featured) ? 'Filme' : 'Série'}
          </span>
          <h1 className="text-3xl md:text-6xl font-extrabold text-white tracking-tight drop-shadow-lg line-clamp-2">{featured.title}</h1>
          <div className="flex flex-wrap items-center gap-3 text-sm text-[#D6D4E8]">
            {featured.rating > 0 && (
              <span className="text-[#1FCFAE] font-bold">{Math.round(featured.rating * 10)}% relevante</span>
            )}
            {isVod(featured) && featured.year > 0 && <span>{featured.year}</span>}
            {isVod(featured) && featured.durationMinutes > 0 && (
              <span>
                {Math.floor(featured.durationMinutes / 60) > 0 ? `${Math.floor(featured.durationMinutes / 60)}h ` : ''}
                {featured.durationMinutes % 60}min
              </span>
            )}
            {!isVod(featured) && featured.seasons.length > 0 && <span>{featured.seasons.length} temporada(s)</span>}
            <span className="px-2 py-0.5 rounded border border-white/30 text-xs">{featured.category}</span>
          </div>
          <p className="text-sm md:text-lg text-[#D6D4E8] line-clamp-3 max-w-2xl drop-shadow">
            {isVod(featured) ? featured.description : featured.overview}
          </p>
          <div className="flex flex-wrap items-center gap-3 pt-2">
            <button
              data-autofocus
              onClick={() => (isVod(featured) ? playVod(featured) : openSeries(featured))}
              data-tv-title={`Assistir ${featured.title}`}
              className="tv-card px-8 py-3.5 rounded-xl bg-white text-[#07070F] font-bold text-base flex items-center gap-2.5 cursor-pointer focus:outline-none"
            >
              <Play className="w-5 h-5 fill-current" /> {getResumeSeconds(featured.id) > 0 ? 'Continuar' : 'Assistir'}
            </button>
            <button
              onClick={() => (isVod(featured) ? openVod(featured) : openSeries(featured))}
              data-tv-title={`Mais informações: ${featured.title}`}
              className="tv-card px-6 py-3.5 rounded-xl bg-white/20 text-white font-semibold text-base flex items-center gap-2 cursor-pointer focus:outline-none backdrop-blur-sm"
            >
              <Info className="w-5 h-5" /> Mais informações
            </button>
            <button
              onClick={() => toggleMyList(featured.id)}
              data-tv-title={isInMyList(featured.id) ? 'Remover da minha lista' : 'Adicionar à minha lista'}
              className="tv-card w-12 h-12 rounded-full border-2 border-white/60 text-white flex items-center justify-center cursor-pointer focus:outline-none"
              title="Minha lista"
            >
              {isInMyList(featured.id) ? <Check className="w-5 h-5" /> : <Plus className="w-5 h-5" />}
            </button>
          </div>
        </section>
      ) : (
        heroChannel && (
          <div className="relative rounded-3xl overflow-hidden bg-[#16162A] border border-[#6B4FE0]/40 p-6 md:p-12 flex items-center justify-between gap-6">
            <div className="space-y-4">
              <span className="px-3 py-1 rounded-lg bg-[#1FCFAE]/20 text-[#1FCFAE] font-bold text-xs uppercase tracking-wider border border-[#1FCFAE]/40">Ao vivo</span>
              <h1 className="text-3xl md:text-5xl font-extrabold text-white">{heroChannel.name}</h1>
              <button
                data-autofocus
                onClick={() => playChannel(heroChannel)}
                data-tv-title={`Assistir ${heroChannel.name}`}
                className="tv-card px-7 py-3.5 rounded-2xl bg-[#6B4FE0] text-white font-bold text-sm flex items-center gap-2.5 cursor-pointer focus:outline-none"
              >
                <Play className="w-5 h-5 fill-current" /> Assistir ao vivo
              </button>
            </div>
            {heroChannel.logoUrl && <img src={heroChannel.logoUrl} alt="" className="hidden md:block max-h-32 max-w-[240px] object-contain" />}
          </div>
        )
      )}

      <div className="relative z-10 space-y-9">
      <MediaRow title="Continuar assistindo" icon={<History className="w-4 h-4 text-[#FF5468]" />} itemWidth="w-56 md:w-64" onSeeAll={() => setActiveTab('history')}>
        {continueWatchingItems.map((item) => (
          <PosterCard
            key={item.id}
            aspect="landscape"
            title={item.title}
            subtitle={item.subtitle}
            imageUrl={item.posterUrl}
            progress={getProgressFraction(item.contentId)}
            tvTitle={`Continuar: ${item.title}`}
            onSelect={() => resumeHistoryItem(item)}
          />
        ))}
      </MediaRow>

      <MediaRow title="Minha lista" icon={<Plus className="w-4 h-4 text-white" />} onSeeAll={() => setActiveTab('mylist')}>
        {rows.myListItems.map((it) =>
          isVod(it) ? (
            <PosterCard key={it.id} title={it.title} subtitle={it.category} imageUrl={it.posterUrl} rating={it.rating} progress={getProgressFraction(it.id)} onSelect={() => openVod(it)} onFocused={() => featureItem(it)} />
          ) : (
            <PosterCard key={it.id} title={it.title} subtitle={it.category} imageUrl={it.posterUrl} rating={it.rating} badge="Série" onSelect={() => openSeries(it)} onFocused={() => featureItem(it)} />
          )
        )}
      </MediaRow>

      {rows.recentChannels.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center gap-2">
            <Radio className="w-4 h-4 text-[#1FCFAE]" />
            <h2 className="text-base font-bold text-white tracking-wide">Assistidos recentemente</h2>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {rows.recentChannels.slice(0, 4).map((ch) => (
              <ChannelCard key={ch.id} channel={ch} />
            ))}
          </div>
        </section>
      )}

      <MediaRow title="Canais favoritos" icon={<Heart className="w-4 h-4 text-[#FF6F91]" />} itemWidth="w-40" onSeeAll={() => setActiveTab('favorites')}>
        {rows.favChannels.map((ch) => (
          <PosterCard key={ch.id} aspect="logo" title={ch.name} subtitle={ch.groupTitle} imageUrl={ch.logoUrl} onSelect={() => playChannel(ch)} />
        ))}
      </MediaRow>

      <MediaRow title="Adicionados recentemente" icon={<Sparkles className="w-4 h-4 text-[#1FCFAE]" />} onSeeAll={() => setActiveTab('vod')}>
        {rows.recentVod.map((v) => (
          <PosterCard key={v.id} title={v.title} subtitle={v.year ? String(v.year) : v.category} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} onFocused={() => featureItem(v)} />
        ))}
      </MediaRow>

      <MediaRow title="Top 10 mais bem avaliados" icon={<Star className="w-4 h-4 text-[#FF6F91]" />} itemWidth="w-52 md:w-56" onSeeAll={() => setActiveTab('vod')}>
        {rows.topRated.slice(0, 10).map((v, i) => (
          <div key={v.id} className="relative pl-14">
            <span
              aria-hidden
              className="absolute left-0 bottom-10 text-[110px] leading-none font-black text-[#07070F] select-none pointer-events-none"
              style={{ WebkitTextStroke: '3px rgba(245,243,255,0.8)', fontFamily: 'Outfit, sans-serif' }}
            >
              {i + 1}
            </span>
            <PosterCard title={v.title} subtitle={v.category} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} onFocused={() => featureItem(v)} />
          </div>
        ))}
      </MediaRow>

      <MediaRow title="Séries" icon={<Layers className="w-4 h-4 text-[#6B4FE0]" />} onSeeAll={() => setActiveTab('series')}>
        {rows.recentSeries.map((s) => (
          <PosterCard key={s.id} title={s.title} subtitle={s.category} imageUrl={s.posterUrl} rating={s.rating} onSelect={() => openSeries(s)} onVisible={() => enrichArtwork('series', s.id)} onFocused={() => featureItem(s)} />
        ))}
      </MediaRow>

      {rows.vodCats.map(({ cat, items }) => (
        <MediaRow key={cat} title={cat} icon={<Clapperboard className="w-4 h-4 text-[#A8A6C0]" />} onSeeAll={() => setActiveTab('vod')}>
          {items.map((v) => (
            <PosterCard key={v.id} title={v.title} subtitle={v.year ? String(v.year) : undefined} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} onFocused={() => featureItem(v)} />
          ))}
        </MediaRow>
      ))}

      {filteredChannels.length > 0 && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-[#1FCFAE]" />
              <h2 className="text-base font-bold text-white tracking-wide">Canais ao vivo</h2>
            </div>
            <button
              onClick={() => setActiveTab('channels')}
              data-tv-skip
              data-tv-title="Ver todos os canais"
              className="tv-card text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-medium flex items-center gap-1 cursor-pointer px-2 py-1 rounded-lg focus:outline-none"
            >
              <Tv className="w-3.5 h-3.5" /> Ver todos ({filteredChannels.length})
            </button>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {filteredChannels.slice(0, 8).map((ch, idx) => (
              <ChannelCard key={ch.id} channel={ch} index={idx} />
            ))}
          </div>
        </section>
      )}

      {vodItems.length === 0 && seriesItems.length === 0 && (
        <p className="text-xs text-[#A8A6C0] flex items-center gap-2">
          <Film className="w-4 h-4" /> Sua lista não trouxe filmes nem séries. Listas Xtream normalmente incluem os dois.
        </p>
      )}
      </div>
    </div>
  );
};
