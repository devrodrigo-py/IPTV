import React, { useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import { PageHeader } from '../components/common/PageHeader';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';
import { CategoryChips } from '../components/channels/CategoryChips';
import { useProgressiveList } from '../hooks/useProgressiveList';

type SortMode = 'default' | 'recent' | 'rating' | 'title';

export const VodView: React.FC = () => {
  const { vodItems, setSelectedVodModal, getProgressFraction, enrichArtwork, tvMode } = useApp();
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
    <div className="px-14 pt-10 pb-12 space-y-6 select-none">
      <PageHeader
        title="Filmes"
        subtitle={`${filtered.length} de ${vodItems.length} filmes`}
        actions={
          !tvMode && (
            <>
              <div className="relative">
                <Search className="w-4 h-4 text-white/40 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Buscar filme"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  className="bg-white/5 text-sm text-white placeholder-white/40 pl-9 pr-3 h-10 rounded-md outline-none focus:bg-white/10"
                />
              </div>
              <select
                value={sort}
                onChange={(e) => setSort(e.target.value as SortMode)}
                className="bg-white/5 text-sm text-white px-3 h-10 rounded-md outline-none"
              >
                <option value="default">Ordem da lista</option>
                <option value="recent">Mais recentes</option>
                <option value="rating">Melhor avaliados</option>
                <option value="title">A–Z</option>
              </select>
            </>
          )
        }
      />

      <CategoryChips categories={categories} selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {filtered.length === 0 ? (
        <div className="py-16 text-white/50 text-lg">
          {vodItems.length === 0 ? 'Nenhum filme nas suas listas ativas.' : 'Nenhum filme encontrado com esse filtro.'}
        </div>
      ) : (
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 2xl:grid-cols-8 gap-x-4 gap-y-6">
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
