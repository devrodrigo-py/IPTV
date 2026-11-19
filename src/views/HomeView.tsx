import React, { useMemo } from 'react';
import { Play, Tv, Film, Heart, History, Radio, Clapperboard, Sparkles, ListPlus, Info, Star, TrendingUp, Layers } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { MediaRow } from '../components/media/MediaRow';
import { PosterCard } from '../components/media/PosterCard';
import { SeriesItem, VodItem } from '../types';

const ROW_LIMIT = 20;

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
    return { recentVod, topRated, recentSeries, vodCats, favChannels, recentChannels, hero };
  }, [vodItems, seriesItems, filteredChannels, favorites, history]);

  const openVod = (v: VodItem) => setSelectedVodModal(v);
  const openSeries = (s: SeriesItem) => setSelectedSeriesModal(s);

  if (!isHydrated) {
    return (
      <div className="h-full flex items-center justify-center text-[#A8A6C0] text-sm gap-3">
        <div className="w-6 h-6 rounded-full border-2 border-t-[#1FCFAE] border-[#6B4FE0]/30 animate-spin" />
        Carregando sua biblioteca…
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

  const hero = rows.hero;
  const heroIsVod = hero && 'streamUrl' in hero;
  const heroChannel = filteredChannels[0];

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-9 select-none">
      {/* Hero */}
      {hero ? (
        <div className="relative rounded-3xl overflow-hidden bg-[#16162A] border border-[#6B4FE0]/30 shadow-2xl min-h-[260px] md:min-h-[380px] flex items-end">
          {(hero.backdropUrl || hero.posterUrl) && (
            <img src={hero.backdropUrl || hero.posterUrl} alt="" className="absolute inset-0 w-full h-full object-cover opacity-70" />
          )}
          <div className="absolute inset-0 scrim-hero-tv" />
          <div className="relative z-10 p-6 md:p-12 max-w-2xl space-y-4">
            <span className="px-3 py-1 rounded-lg bg-[#FF6F91]/20 text-[#FF6F91] font-bold text-xs uppercase tracking-wider border border-[#FF6F91]/40">
              {heroIsVod ? 'Filme em destaque' : 'Série em destaque'}
            </span>
            <h1 className="text-3xl md:text-5xl font-extrabold text-white tracking-tight drop-shadow-md">{hero.title}</h1>
            <p className="text-sm md:text-base text-[#D6D4E8] line-clamp-3">{'description' in hero ? hero.description : hero.overview}</p>
            <div className="flex items-center gap-3 pt-2">
              <button
                onClick={() => (heroIsVod ? playVod(hero as VodItem) : openSeries(hero as SeriesItem))}
                data-tv-title={`Assistir ${hero.title}`}
                className="tv-card px-7 py-3.5 rounded-2xl bg-white text-[#07070F] font-bold text-sm md:text-base flex items-center gap-2.5 cursor-pointer focus:outline-none"
              >
                <Play className="w-5 h-5 fill-current" /> Assistir
              </button>
              <button
                onClick={() => (heroIsVod ? openVod(hero as VodItem) : openSeries(hero as SeriesItem))}
                data-tv-title={`Mais informações: ${hero.title}`}
                className="tv-card px-6 py-3.5 rounded-2xl bg-white/15 text-white font-semibold text-sm md:text-base flex items-center gap-2 cursor-pointer focus:outline-none"
              >
                <Info className="w-5 h-5" /> Mais informações
              </button>
            </div>
          </div>
        </div>
      ) : (
        heroChannel && (
          <div className="relative rounded-3xl overflow-hidden bg-[#16162A] border border-[#6B4FE0]/40 p-6 md:p-12 flex items-center justify-between gap-6">
            <div className="space-y-4">
              <span className="px-3 py-1 rounded-lg bg-[#1FCFAE]/20 text-[#1FCFAE] font-bold text-xs uppercase tracking-wider border border-[#1FCFAE]/40">Ao vivo</span>
              <h1 className="text-3xl md:text-5xl font-extrabold text-white">{heroChannel.name}</h1>
              <button
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
          <PosterCard key={v.id} title={v.title} subtitle={v.year ? String(v.year) : v.category} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} />
        ))}
      </MediaRow>

      <MediaRow title="Mais bem avaliados" icon={<Star className="w-4 h-4 text-[#FF6F91]" />} onSeeAll={() => setActiveTab('vod')}>
        {rows.topRated.map((v) => (
          <PosterCard key={v.id} title={v.title} subtitle={v.category} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} />
        ))}
      </MediaRow>

      <MediaRow title="Séries" icon={<Layers className="w-4 h-4 text-[#6B4FE0]" />} onSeeAll={() => setActiveTab('series')}>
        {rows.recentSeries.map((s) => (
          <PosterCard key={s.id} title={s.title} subtitle={s.category} imageUrl={s.posterUrl} rating={s.rating} onSelect={() => openSeries(s)} onVisible={() => enrichArtwork('series', s.id)} />
        ))}
      </MediaRow>

      {rows.vodCats.map(({ cat, items }) => (
        <MediaRow key={cat} title={cat} icon={<Clapperboard className="w-4 h-4 text-[#A8A6C0]" />} onSeeAll={() => setActiveTab('vod')}>
          {items.map((v) => (
            <PosterCard key={v.id} title={v.title} subtitle={v.year ? String(v.year) : undefined} imageUrl={v.posterUrl} rating={v.rating} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} />
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
  );
};
