import React, { useMemo } from 'react';
import { Plus } from 'lucide-react';
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
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      <div className="pb-4 border-b border-[#2A2A31]">
        <div className="flex items-center gap-2">
          <Plus className="w-5 h-5 text-[#7C5CFF]" />
          <h1 className="text-xl font-bold text-white tracking-tight">Minha lista</h1>
        </div>
        <p className="text-xs text-[#A1A1AA] mt-0.5">Filmes e séries que você salvou para assistir depois.</p>
      </div>

      {items.length === 0 ? (
        <div className="p-12 text-center bg-[#141418]/50 rounded-3xl border border-[#2A2A31] space-y-4">
          <p className="text-sm text-[#A1A1AA]">
            Sua lista está vazia. Abra um filme ou uma série e escolha <strong className="text-white">+ Minha lista</strong>.
          </p>
          <button
            data-autofocus
            onClick={() => setActiveTab('vod')}
            data-tv-title="Explorar filmes"
            className="tv-card px-5 py-2.5 rounded-xl bg-[#7C5CFF] text-white font-bold text-xs cursor-pointer focus:outline-none"
          >
            Explorar filmes
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 2xl:grid-cols-8 gap-4">
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
