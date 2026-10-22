import React from 'react';
import { Tv, Star, Layers, Play } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { SeriesDetailModal } from '../components/series/SeriesDetailModal';

export const SeriesView: React.FC = () => {
  const { seriesItems, selectedSeriesModal, setSelectedSeriesModal } = useApp();

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="pb-4 border-b border-[#2A2A45]">
        <div className="flex items-center gap-2">
          <Tv className="w-5 h-5 text-[#6B4FE0]" />
          <h1 className="text-xl font-bold text-white tracking-tight">Séries e Temporadas</h1>
        </div>
        <p className="text-xs text-[#A8A6C0] mt-0.5">
          Acesse episódios organizados por temporada com suporte a reprodução contínua.
        </p>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-5">
        {seriesItems.map((series) => {
          const totalEpisodes = series.seasons.reduce((acc, s) => acc + s.episodes.length, 0);

          return (
            <div
              key={series.id}
              onClick={() => setSelectedSeriesModal(series)}
              className="tv-card group bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0]/60 overflow-hidden cursor-pointer flex flex-col justify-between transition-all duration-200 shadow-md hover:shadow-xl hover:shadow-[#6B4FE0]/15"
            >
              <div className="relative aspect-[16/10] w-full bg-black/40 overflow-hidden">
                <img
                  src={series.backdropUrl || series.posterUrl}
                  alt={series.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />

                <div className="absolute top-2.5 right-2.5 px-2 py-0.5 rounded-md bg-black/70 backdrop-blur-md text-[11px] font-bold text-[#FF6F91] flex items-center gap-1 border border-white/10">
                  <Star className="w-3 h-3 fill-current" />
                  {series.rating}
                </div>

                <div className="absolute inset-0 bg-black/50 backdrop-blur-[1px] opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                  <div className="w-12 h-12 rounded-full bg-[#6B4FE0] text-white flex items-center justify-center shadow-lg shadow-[#6B4FE0]/50 transform group-hover:scale-105 transition-transform">
                    <Play className="w-5 h-5 fill-current ml-0.5" />
                  </div>
                </div>
              </div>

              <div className="p-4">
                <h3 className="font-bold text-sm text-white truncate group-hover:text-[#1FCFAE] transition-colors">
                  {series.title}
                </h3>
                <p className="text-xs text-[#A8A6C0] line-clamp-2 mt-1 leading-relaxed">
                  {series.overview}
                </p>

                <div className="flex items-center justify-between text-xs text-[#A8A6C0] mt-3 pt-2 border-t border-[#2A2A45]/50">
                  <span className="flex items-center gap-1 font-mono text-[11px]">
                    <Layers className="w-3.5 h-3.5 text-[#6B4FE0]" />
                    {series.seasons.length} Temp. ({totalEpisodes} eps)
                  </span>
                  <span className="text-[11px] font-medium text-[#1FCFAE]">
                    {series.category}
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Series Detail Modal */}
      {selectedSeriesModal && (
        <SeriesDetailModal
          series={selectedSeriesModal}
          onClose={() => setSelectedSeriesModal(null)}
        />
      )}
    </div>
  );
};
