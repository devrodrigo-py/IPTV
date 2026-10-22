import React, { useState } from 'react';
import { Search, Tv, Film, Play, Star } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { VodModal } from '../components/vod/VodModal';
import { SeriesDetailModal } from '../components/series/SeriesDetailModal';
import { VodItem, SeriesItem } from '../types';

export const SearchView: React.FC = () => {
  const {
    searchQuery,
    setSearchQuery,
    filteredChannels,
    vodItems,
    seriesItems,
    selectedVodModal,
    setSelectedVodModal,
    selectedSeriesModal,
    setSelectedSeriesModal,
  } = useApp();

  const [activeFilter, setActiveFilter] = useState<'all' | 'channels' | 'vod' | 'series'>('all');

  const q = searchQuery.toLowerCase().trim();

  const matchedChannels = filteredChannels.filter((c) => {
    if (!q) return true;
    return c.name.toLowerCase().includes(q) || (c.groupTitle || '').toLowerCase().includes(q);
  });

  const matchedVod = vodItems.filter((v) => {
    if (!q) return true;
    return (
      v.title.toLowerCase().includes(q) ||
      v.category.toLowerCase().includes(q) ||
      v.description.toLowerCase().includes(q)
    );
  });

  const matchedSeries = seriesItems.filter((s) => {
    if (!q) return true;
    return (
      s.title.toLowerCase().includes(q) ||
      s.category.toLowerCase().includes(q) ||
      s.overview.toLowerCase().includes(q)
    );
  });

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 select-none">
      {/* Header and Search input */}
      <div className="space-y-4 pb-4 border-b border-[#2A2A45]">
        <div className="flex items-center gap-2">
          <Search className="w-5 h-5 text-[#6B4FE0]" />
          <h1 className="text-xl font-bold text-white tracking-tight">Busca Global</h1>
        </div>

        <div className="relative max-w-2xl">
          <Search className="w-5 h-5 text-[#A8A6C0] absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Pesquise por nome do canal, filme, série, ator ou categoria..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#16162A] text-sm text-white placeholder-[#A8A6C0] pl-12 pr-4 py-3 rounded-2xl border border-[#2A2A45] focus:border-[#6B4FE0] outline-none shadow-inner"
            autoFocus
          />
        </div>

        {/* Filter Pills */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveFilter('all')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'all'
                ? 'bg-[#6B4FE0] text-white'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
            }`}
          >
            Tudo ({matchedChannels.length + matchedVod.length + matchedSeries.length})
          </button>
          <button
            onClick={() => setActiveFilter('channels')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'channels'
                ? 'bg-[#6B4FE0] text-white'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
            }`}
          >
            Canais ({matchedChannels.length})
          </button>
          <button
            onClick={() => setActiveFilter('vod')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'vod'
                ? 'bg-[#6B4FE0] text-white'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
            }`}
          >
            Filmes ({matchedVod.length})
          </button>
          <button
            onClick={() => setActiveFilter('series')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'series'
                ? 'bg-[#6B4FE0] text-white'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
            }`}
          >
            Séries ({matchedSeries.length})
          </button>
        </div>
      </div>

      {/* Results */}
      {(activeFilter === 'all' || activeFilter === 'channels') && matchedChannels.length > 0 && (
        <section className="space-y-3">
          <h2 className="text-sm font-bold text-[#A8A6C0] uppercase tracking-wider">
            Canais Ao Vivo ({matchedChannels.length})
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {matchedChannels.map((ch, idx) => (
              <ChannelCard key={ch.id} channel={ch} index={idx} />
            ))}
          </div>
        </section>
      )}

      {(activeFilter === 'all' || activeFilter === 'vod') && matchedVod.length > 0 && (
        <section className="space-y-3 pt-4">
          <h2 className="text-sm font-bold text-[#A8A6C0] uppercase tracking-wider">
            Filmes (VOD) ({matchedVod.length})
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {matchedVod.map((vod) => (
              <div
                key={vod.id}
                onClick={() => setSelectedVodModal(vod)}
                className="group bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0] overflow-hidden cursor-pointer transition-all"
              >
                <div className="relative aspect-[2/3] w-full bg-black/40 overflow-hidden">
                  <img
                    src={vod.posterUrl}
                    alt={vod.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                  <div className="absolute top-2 right-2 px-1.5 py-0.5 rounded bg-black/70 text-[10px] font-bold text-[#FF6F91]">
                    ★ {vod.rating}
                  </div>
                </div>
                <div className="p-2.5">
                  <h4 className="font-bold text-xs text-white truncate">{vod.title}</h4>
                  <p className="text-[10px] text-[#A8A6C0] mt-0.5">{vod.category}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {(activeFilter === 'all' || activeFilter === 'series') && matchedSeries.length > 0 && (
        <section className="space-y-3 pt-4">
          <h2 className="text-sm font-bold text-[#A8A6C0] uppercase tracking-wider">
            Séries ({matchedSeries.length})
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
            {matchedSeries.map((series) => (
              <div
                key={series.id}
                onClick={() => setSelectedSeriesModal(series)}
                className="group bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0] p-3 cursor-pointer transition-all"
              >
                <h4 className="font-bold text-xs text-white truncate">{series.title}</h4>
                <p className="text-[10px] text-[#A8A6C0] mt-0.5 line-clamp-1">{series.overview}</p>
              </div>
            ))}
          </div>
        </section>
      )}

      {selectedVodModal && (
        <VodModal vod={selectedVodModal} onClose={() => setSelectedVodModal(null)} />
      )}

      {selectedSeriesModal && (
        <SeriesDetailModal
          series={selectedSeriesModal}
          onClose={() => setSelectedSeriesModal(null)}
        />
      )}
    </div>
  );
};
