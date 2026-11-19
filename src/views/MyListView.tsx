import React, { useMemo } from 'react';
import { PageHeader } from '../components/common/PageHeader';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';

export const MyListView: React.FC = () => {
  const { myList, vodItems, seriesItems, setSelectedVodModal, setSelectedSeriesModal, getProgressFraction, setActiveTab } = useApp();

  const items = useMemo(() => {
    const vod = new Map(vodItems.map((v) => [v.id, v]));
    const ser = new Map(seriesItems.map((s) => [s.id, s]));
    return myList
      .map((id) => (vod.has(id) ? { kind: 'vod' as const, v: vod.get(id)! } : ser.has(id) ? { kind: 'series' as const, s: ser.get(id)! } : null))
      .filter((x): x is NonNullable<typeof x> => x !== null);
  }, [myList, vodItems, seriesItems]);

  return (
    <div className="px-14 pt-10 pb-12 space-y-6 select-none">
      <PageHeader title="Minha lista" subtitle="Filmes e séries que você salvou para assistir depois." />

      {items.length === 0 ? (
        <div className="py-16 space-y-6 max-w-xl">
          <p className="text-lg text-white/60">
            Sua lista está vazia. Abra um filme ou uma série e escolha <strong className="text-white">+ Minha lista</strong>.
          </p>
          <button
            data-autofocus
            onClick={() => setActiveTab('vod')}
            data-tv-title="Explorar filmes"
            className="tv-card h-12 px-6 rounded-md bg-white text-black font-bold cursor-pointer focus:outline-none"
          >
            Explorar filmes
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 2xl:grid-cols-8 gap-x-4 gap-y-6">
          {items.map((it) =>
            it.kind === 'vod' ? (
              <PosterCard key={it.v.id} title={it.v.title} subtitle={it.v.category} imageUrl={it.v.posterUrl} rating={it.v.rating} progress={getProgressFraction(it.v.id)} onSelect={() => setSelectedVodModal(it.v)} />
            ) : (
              <PosterCard key={it.s.id} title={it.s.title} subtitle={it.s.category} imageUrl={it.s.posterUrl} rating={it.s.rating} badge="Série" onSelect={() => setSelectedSeriesModal(it.s)} />
            )
          )}
        </div>
      )}
    </div>
  );
};
