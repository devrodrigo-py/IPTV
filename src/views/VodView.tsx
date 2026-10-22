import React, { useState } from 'react';
import { Film, Star, Clock, Play, Filter } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { VodItem } from '../types';
import { VodModal } from '../components/vod/VodModal';

export const VodView: React.FC = () => {
  const { vodItems, playVod, selectedVodModal, setSelectedVodModal } = useApp();
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const categories = Array.from(new Set(vodItems.map((v) => v.category))).sort();

  const filtered = vodItems.filter((v) => {
    if (selectedCategory !== 'all' && v.category !== selectedCategory) return false;
    return true;
  });

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <Film className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Filmes sob Demanda (VOD)</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Catálogo completo com sinopses, avaliações e reprodução instantânea.
          </p>
        </div>

        {/* Categories Pills */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
          <button
            onClick={() => setSelectedCategory('all')}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap cursor-pointer transition-all ${
              selectedCategory === 'all'
                ? 'bg-[#6B4FE0] text-white'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
            }`}
          >
            Todos
          </button>
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap cursor-pointer transition-all ${
                selectedCategory === cat
                  ? 'bg-[#6B4FE0] text-white'
                  : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {filtered.map((vod) => (
          <div
            key={vod.id}
            tabIndex={0}
            data-tv-title={`Filme: ${vod.title}`}
            onClick={() => setSelectedVodModal(vod)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') setSelectedVodModal(vod);
            }}
            className="tv-card group bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0]/60 overflow-hidden cursor-pointer flex flex-col justify-between transition-all duration-200 shadow-md hover:shadow-xl hover:shadow-[#6B4FE0]/15 focus:outline-none"
          >
            <div className="relative aspect-[2/3] w-full bg-black/40 overflow-hidden">
              <img
                src={vod.posterUrl}
                alt={vod.title}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              />

              <div className="absolute top-2.5 right-2.5 px-2 py-0.5 rounded-md bg-black/70 backdrop-blur-md text-[11px] font-bold text-[#FF6F91] flex items-center gap-1 border border-white/10">
                <Star className="w-3 h-3 fill-current" />
                {vod.rating}
              </div>

              {/* Hover Overlay */}
              <div className="absolute inset-0 bg-black/50 backdrop-blur-[1px] opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                <div className="w-12 h-12 rounded-full bg-[#6B4FE0] text-white flex items-center justify-center shadow-lg shadow-[#6B4FE0]/50 transform group-hover:scale-105 transition-transform">
                  <Play className="w-5 h-5 fill-current ml-0.5" />
                </div>
              </div>
            </div>

            <div className="p-3">
              <h3 className="font-bold text-xs text-white truncate group-hover:text-[#1FCFAE] transition-colors">
                {vod.title}
              </h3>
              <div className="flex items-center justify-between text-[11px] text-[#A8A6C0] mt-1">
                <span>{vod.year}</span>
                <span>{vod.durationMinutes} min</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modal */}
      {selectedVodModal && (
        <VodModal vod={selectedVodModal} onClose={() => setSelectedVodModal(null)} />
      )}
    </div>
  );
};
