import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Play, Info, Plus, Check, ListPlus } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelTile } from '../components/channels/ChannelTile';
import { NebulaLogo } from '../components/brand/NebulaLogo';
import { Billboard } from '../components/media/Billboard';
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
    tvMode,
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
    const all = [...vodItems, ...seriesItems] as Featured[];
    const byRating = (a: Featured, b: Featured) => b.rating - a.rating;
    const withBackdrop = all.filter((x) => x.backdropUrl).sort(byRating).slice(0, 6);
    if (withBackdrop.length) return withBackdrop;
    // Provider lists rarely ship backdrops: poster-only billboards still look right.
    const withPoster = all.filter((x) => x.posterUrl).sort(byRating).slice(0, 6);
    return withPoster.length ? withPoster : rows.hero ? [rows.hero as Featured] : [];
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
  const channelNumber = useMemo(() => new Map(filteredChannels.map((c, i) => [c.id, i + 1])), [filteredChannels]);

  if (!isHydrated) {
    return (
      <div className="px-14 pt-[16vh] space-y-10 animate-pulse" aria-label="Carregando sua biblioteca">
        <div className="space-y-4 max-w-xl">
          <div className="h-14 w-3/4 rounded bg-white/5" />
          <div className="h-4 w-1/2 rounded bg-white/5" />
          <div className="h-4 w-full rounded bg-white/5" />
        </div>
        <div className="flex gap-4 overflow-hidden pt-16">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="w-44 h-[264px] shrink-0 rounded-lg bg-white/5" />
          ))}
        </div>
      </div>
    );
  }

  const isEmpty = playlists.length === 0 || (filteredChannels.length === 0 && vodItems.length === 0 && seriesItems.length === 0);

  if (isEmpty) {
    return (
      <div className="relative min-h-full flex items-center px-14 py-16 overflow-hidden">
        <div className="absolute inset-0 pointer-events-none" aria-hidden>
          <div className="absolute -top-1/3 right-[-10%] w-[70vw] h-[70vw] rounded-full bg-[#7C5CFF]/20 blur-[120px]" />
          <div className="absolute bottom-[-30%] right-[20%] w-[40vw] h-[40vw] rounded-full bg-[#FF4D8D]/10 blur-[120px]" />
        </div>
        <div className="relative max-w-2xl space-y-8">
          <NebulaLogo size={48} />
          <h1 className="font-display text-5xl md:text-6xl font-extrabold text-white leading-[1.02] tracking-tight">
            Tudo o que você assiste, em um só lugar.
          </h1>
          <p className="text-lg text-white/70 leading-relaxed">
            Adicione a lista do seu provedor (M3U ou login Xtream Codes) e o Nebula organiza canais ao vivo, filmes e séries com
            guia de programação, “continuar assistindo” e muito mais.
          </p>
          {syncStatus && <p className="text-sm text-[#B9A8FF]">{syncStatus.step}</p>}
          <div className="flex flex-wrap gap-4">
            <button
              data-autofocus
              onClick={() => setActiveTab('playlists')}
              data-tv-title="Adicionar minha lista"
              className="tv-card px-8 py-4 rounded-md bg-white text-black font-bold text-lg flex items-center gap-3 cursor-pointer focus:outline-none"
            >
              <ListPlus className="w-6 h-6" /> Adicionar minha lista
            </button>
            <button
              onClick={loadDemoContent}
              data-tv-title="Ver demonstração"
              className="tv-card px-8 py-4 rounded-md bg-white/15 text-white font-semibold text-lg flex items-center gap-3 cursor-pointer focus:outline-none"
            >
              <Play className="w-6 h-6" /> Ver demonstração
            </button>
          </div>
          <p className="text-xs text-white/40 max-w-lg">
            O Nebula é um player: não fornece, vende nem hospeda canais ou filmes. Use apenas conteúdos que você tem direito de acessar.
          </p>
        </div>
      </div>
    );
  }

  const heroChannel = filteredChannels[0];
  const poster = (v: VodItem) => (
    <PosterCard key={v.id} title={v.title} subtitle={v.category} imageUrl={v.posterUrl} progress={getProgressFraction(v.id)} onSelect={() => openVod(v)} onVisible={() => enrichArtwork('vod', v.id)} onFocused={() => featureItem(v)} />
  );
  const seriesPoster = (x: SeriesItem) => (
    <PosterCard key={x.id} title={x.title} subtitle={x.category} imageUrl={x.posterUrl} onSelect={() => openSeries(x)} onVisible={() => enrichArtwork('series', x.id)} onFocused={() => featureItem(x)} />
  );

  return (
    // TV: the billboard stays put and only the rows scroll below it, always
    // describing the focused title. Elsewhere the page scrolls normally.
    <div className={`relative select-none ${tvMode ? 'h-full flex flex-col overflow-hidden' : 'min-h-full'}`}>
      {featured ? (
        <Billboard
          layout={tvMode ? 'tv' : 'page'}
          item={featured}
          resumeSeconds={getResumeSeconds(featured.id)}
          inMyList={isInMyList(featured.id)}
          onPlay={() => (isVod(featured) ? playVod(featured) : openSeries(featured))}
          onInfo={() => (isVod(featured) ? openVod(featured) : openSeries(featured))}
          onToggleList={() => toggleMyList(featured.id)}
        />
      ) : (
        heroChannel && (
          <section className="relative px-14 pt-[14vh] pb-10 max-w-3xl space-y-5">
            <span className="flex items-center gap-2 text-xs font-bold tracking-[0.2em] text-white/70">
              <span className="w-2 h-2 rounded-full bg-[#FF3B4E]" /> AO VIVO
            </span>
            <h1 className="font-display text-6xl font-extrabold text-white tracking-tight">{heroChannel.name}</h1>
            <button
              data-autofocus
              onClick={() => playChannel(heroChannel)}
              data-tv-title={`Assistir ${heroChannel.name}`}
              className="tv-card px-8 py-3.5 rounded-md bg-white text-black font-bold text-lg flex items-center gap-3 cursor-pointer focus:outline-none"
            >
              <Play className="w-6 h-6 fill-current" /> Assistir
            </button>
          </section>
        )
      )}

      <div
        data-rows={tvMode ? true : undefined}
        className={`relative z-10 px-14 space-y-1 ${tvMode ? 'flex-1 min-h-0 overflow-y-auto scrollbar-none pb-[30vh]' : '-mt-[14vh] pb-16'}`}
        style={tvMode ? { WebkitMaskImage: 'linear-gradient(to bottom, transparent 0, #000 28px)' } : undefined}
      >
        <MediaRow title="Continuar assistindo" itemWidth="w-80" onSeeAll={() => setActiveTab('history')}>
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

        <MediaRow title="Minha lista" onSeeAll={() => setActiveTab('mylist')}>
          {rows.myListItems.map((it) => (isVod(it) ? poster(it) : seriesPoster(it)))}
        </MediaRow>

        {rows.topRated.length >= 3 && (
          <MediaRow title="Top 10 no Nebula" itemWidth="w-52">
            {rows.topRated.slice(0, 10).map((v, i) => (
              <div key={v.id} className="relative pl-[64px]">
                <span
                  aria-hidden
                  className="absolute left-0 bottom-0 font-display font-black leading-[0.8] text-[132px] text-[#060608] select-none pointer-events-none"
                  style={{ WebkitTextStroke: '3px rgba(255,255,255,0.55)', letterSpacing: '-0.08em' }}
                >
                  {i + 1}
                </span>
                {poster(v)}
              </div>
            ))}
          </MediaRow>
        )}

        <MediaRow title="Assistidos recentemente" itemWidth="w-72">
          {rows.recentChannels.map((ch) => (
            <ChannelTile key={ch.id} channel={ch} number={channelNumber.get(ch.id)} />
          ))}
        </MediaRow>

        <MediaRow title="Adicionados recentemente" onSeeAll={() => setActiveTab('vod')}>
          {rows.recentVod.map(poster)}
        </MediaRow>

        <MediaRow title="Séries" onSeeAll={() => setActiveTab('series')}>
          {rows.recentSeries.map(seriesPoster)}
        </MediaRow>

        <MediaRow title="Seus canais favoritos" itemWidth="w-72" onSeeAll={() => setActiveTab('favorites')}>
          {rows.favChannels.map((ch) => (
            <ChannelTile key={ch.id} channel={ch} number={channelNumber.get(ch.id)} />
          ))}
        </MediaRow>

        {rows.vodCats.map(({ cat, items }) => (
          <MediaRow key={cat} title={cat} onSeeAll={() => setActiveTab('vod')}>
            {items.map(poster)}
          </MediaRow>
        ))}

        <MediaRow title="Ao vivo agora" itemWidth="w-72" onSeeAll={() => setActiveTab('channels')}>
          {filteredChannels.slice(0, ROW_LIMIT).map((ch) => (
            <ChannelTile key={ch.id} channel={ch} number={channelNumber.get(ch.id)} />
          ))}
        </MediaRow>
      </div>
    </div>
  );
};

