import React, { useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import { PageHeader } from '../components/common/PageHeader';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';
import { CategoryChips } from '../components/channels/CategoryChips';
import { useProgressiveList } from '../hooks/useProgressiveList';

export const SeriesView: React.FC = () => {
  const { seriesItems, setSelectedSeriesModal, enrichArtwork, tvMode } = useApp();
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [query, setQuery] = useState('');

  const categories = useMemo(() => Array.from(new Set(seriesItems.map((s) => s.category))).sort((a, b) => a.localeCompare(b, 'pt-BR')), [seriesItems]);
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return seriesItems.filter((s) => (selectedCategory === 'all' || s.category === selectedCategory) && (!q || s.title.toLowerCase().includes(q)));
  }, [seriesItems, selectedCategory, query]);
  const { visible, hasMore, sentinelRef } = useProgressiveList(filtered, 60);

  return (
    <div className="px-14 pt-10 pb-12 space-y-6 select-none">
      <PageHeader
        title="Séries"
        subtitle={`${filtered.length} de ${seriesItems.length} séries`}
        actions={
          !tvMode && (
            <div className="relative">
              <Search className="w-4 h-4 text-white/40 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Buscar série"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="bg-white/5 text-sm text-white placeholder-white/40 pl-9 pr-3 h-10 rounded-md outline-none focus:bg-white/10"
              />
            </div>
          )
        }
      />

      <CategoryChips categories={categories} selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {filtered.length === 0 ? (
        <div className="py-16 text-white/50 text-lg">
          {seriesItems.length === 0 ? 'Nenhuma série nas suas listas ativas.' : 'Nenhuma série encontrada com esse filtro.'}
        </div>
      ) : (
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 2xl:grid-cols-8 gap-x-4 gap-y-6">
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
