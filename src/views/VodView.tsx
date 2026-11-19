import React, { useMemo, useState } from 'react';
import { Film, Search } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';
import { CategoryChips } from '../components/channels/CategoryChips';
import { useProgressiveList } from '../hooks/useProgressiveList';

type SortMode = 'default' | 'recent' | 'rating' | 'title';

export const VodView: React.FC = () => {
  const { vodItems, setSelectedVodModal, getProgressFraction, enrichArtwork } = useApp();
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<SortMode>('default');

  const categories = useMemo(() => Array.from(new Set(vodItems.map((v) => v.category))).sort((a, b) => a.localeCompare(b, 'pt-BR')), [vodItems]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    const list = vodItems.filter((v) => {
      if (selectedCategory !== 'all' && v.category !== selectedCategory) return false;
      return !q || v.title.toLowerCase().includes(q);
    });
    if (sort === 'recent') list.sort((a, b) => (b.addedAt ?? 0) - (a.addedAt ?? 0));
    else if (sort === 'rating') list.sort((a, b) => b.rating - a.rating);
    else if (sort === 'title') list.sort((a, b) => a.title.localeCompare(b.title, 'pt-BR'));
    return list;
  }, [vodItems, selectedCategory, query, sort]);

  const { visible, hasMore, sentinelRef } = useProgressiveList(filtered, 60);

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A31]">
        <div>
          <div className="flex items-center gap-2">
            <Film className="w-5 h-5 text-[#7C5CFF]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Filmes</h1>
          </div>
          <p className="text-xs text-[#A1A1AA] mt-0.5">{filtered.length} de {vodItems.length} filmes</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-[#A1A1AA] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Buscar filme…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="bg-[#141418] text-xs text-white placeholder-[#A1A1AA] pl-8 pr-3 py-2 rounded-xl border border-[#2A2A31] focus:border-[#7C5CFF] outline-none"
            />
          </div>
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value as SortMode)}
            data-tv-title="Ordenar filmes"
            className="bg-[#141418] text-xs text-white px-3 py-2 rounded-xl border border-[#2A2A31] focus:border-[#7C5CFF] outline-none"
          >
            <option value="default">Ordem da lista</option>
            <option value="recent">Mais recentes</option>
            <option value="rating">Melhor avaliados</option>
            <option value="title">A–Z</option>
          </select>
        </div>
      </div>

      <CategoryChips categories={categories} selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {filtered.length === 0 ? (
        <div className="p-12 text-center bg-[#141418]/50 rounded-3xl border border-[#2A2A31] text-sm text-[#A1A1AA]">
          {vodItems.length === 0 ? 'Nenhum filme nas suas listas ativas.' : 'Nenhum filme encontrado com esse filtro.'}
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 2xl:grid-cols-8 gap-4">
          {visible.map((vod) => (
            <PosterCard
              key={vod.id}
              title={vod.title}
              subtitle={[vod.year || null, vod.durationMinutes ? `${vod.durationMinutes} min` : null].filter(Boolean).join(' • ') || vod.category}
              imageUrl={vod.posterUrl}
              rating={vod.rating}
              progress={getProgressFraction(vod.id)}
              tvTitle={`Filme: ${vod.title}`}
              onSelect={() => setSelectedVodModal(vod)}
              onVisible={() => enrichArtwork('vod', vod.id)}
            />
          ))}
        </div>
      )}
      {hasMore && <div ref={sentinelRef} className="h-10" aria-hidden />}
    </div>
  );
};
