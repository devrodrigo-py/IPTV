import React, { useMemo, useState } from 'react';
import { Tv, Search } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';
import { CategoryChips } from '../components/channels/CategoryChips';
import { useProgressiveList } from '../hooks/useProgressiveList';

export const SeriesView: React.FC = () => {
  const { seriesItems, setSelectedSeriesModal, enrichArtwork } = useApp();
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [query, setQuery] = useState('');

  const categories = useMemo(() => Array.from(new Set(seriesItems.map((s) => s.category))).sort((a, b) => a.localeCompare(b, 'pt-BR')), [seriesItems]);
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return seriesItems.filter((s) => (selectedCategory === 'all' || s.category === selectedCategory) && (!q || s.title.toLowerCase().includes(q)));
  }, [seriesItems, selectedCategory, query]);
  const { visible, hasMore, sentinelRef } = useProgressiveList(filtered, 60);

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A31]">
        <div>
          <div className="flex items-center gap-2">
            <Tv className="w-5 h-5 text-[#7C5CFF]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Séries</h1>
          </div>
          <p className="text-xs text-[#A1A1AA] mt-0.5">{filtered.length} de {seriesItems.length} séries</p>
        </div>
        <div className="relative">
          <Search className="w-3.5 h-3.5 text-[#A1A1AA] absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Buscar série…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="bg-[#141418] text-xs text-white placeholder-[#A1A1AA] pl-8 pr-3 py-2 rounded-xl border border-[#2A2A31] focus:border-[#7C5CFF] outline-none"
          />
        </div>
      </div>

      <CategoryChips categories={categories} selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {filtered.length === 0 ? (
        <div className="p-12 text-center bg-[#141418]/50 rounded-3xl border border-[#2A2A31] text-sm text-[#A1A1AA]">
          {seriesItems.length === 0 ? 'Nenhuma série nas suas listas ativas.' : 'Nenhuma série encontrada com esse filtro.'}
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 2xl:grid-cols-8 gap-4">
          {visible.map((s) => (
            <PosterCard
              key={s.id}
              title={s.title}
              subtitle={s.category}
              imageUrl={s.posterUrl}
              rating={s.rating}
              tvTitle={`Série: ${s.title}`}
              onSelect={() => setSelectedSeriesModal(s)}
              onVisible={() => enrichArtwork('series', s.id)}
            />
          ))}
        </div>
      )}
      {hasMore && <div ref={sentinelRef} className="h-10" aria-hidden />}
    </div>
  );
};
