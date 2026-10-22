import React, { useState } from 'react';
import { X, Play, Star, Tv, Layers, Clock } from 'lucide-react';
import { SeriesItem, Episode } from '../../types';
import { useApp } from '../../context/AppContext';

interface SeriesDetailModalProps {
  series: SeriesItem;
  onClose: () => void;
}

export const SeriesDetailModal: React.FC<SeriesDetailModalProps> = ({ series, onClose }) => {
  const { playEpisode } = useApp();
  const [selectedSeasonIdx, setSelectedSeasonIdx] = useState(0);

  const activeSeason = series.seasons[selectedSeasonIdx] || series.seasons[0];

  return (
    <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-3xl bg-[#16162A] border border-[#2A2A45] rounded-3xl overflow-hidden shadow-2xl relative max-h-[85vh] flex flex-col animate-in zoom-in-95 duration-200">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-black/80 text-white flex items-center justify-center cursor-pointer transition-colors"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Backdrop Banner */}
        <div className="relative h-48 w-full bg-black shrink-0">
          <img
            src={series.backdropUrl || series.posterUrl}
            alt={series.title}
            className="w-full h-full object-cover opacity-60"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#16162A] via-[#16162A]/40 to-transparent" />

          <div className="absolute bottom-4 left-6 right-6">
            <div className="flex items-center gap-2 text-xs text-[#A8A6C0] mb-1">
              <span className="flex items-center gap-1 text-[#FF6F91] font-bold">
                <Star className="w-3.5 h-3.5 fill-current" />
                {series.rating} / 10
              </span>
              <span>•</span>
              <span className="text-[#1FCFAE] font-semibold">{series.category}</span>
              <span>•</span>
              <span>{series.seasons.length} Temporada(s)</span>
            </div>
            <h2 className="text-2xl font-black text-white">{series.title}</h2>
          </div>
        </div>

        {/* Synopsis */}
        <div className="px-6 py-3 border-b border-[#2A2A45]/60 text-xs text-[#A8A6C0] leading-relaxed">
          {series.overview}
        </div>

        {/* Season Selector Tabs */}
        <div className="px-6 py-3 bg-[#07070F]/50 border-b border-[#2A2A45] flex items-center gap-2 overflow-x-auto">
          {series.seasons.map((season, idx) => (
            <button
              key={season.seasonNumber}
              onClick={() => setSelectedSeasonIdx(idx)}
              className={`px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                selectedSeasonIdx === idx
                  ? 'bg-[#6B4FE0] text-white shadow-md shadow-[#6B4FE0]/30'
                  : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
              }`}
            >
              {season.title}
            </button>
          ))}
        </div>

        {/* Episode List */}
        <div className="flex-1 overflow-y-auto p-6 space-y-3">
          {activeSeason.episodes.map((ep) => (
            <div
              key={ep.id}
              onClick={() => playEpisode(series, activeSeason.seasonNumber, ep)}
              className="p-3.5 rounded-2xl bg-[#07070F]/80 hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] transition-all cursor-pointer flex items-center justify-between group"
            >
              <div className="flex items-center gap-4 min-w-0 flex-1">
                {/* Thumbnail */}
                <div className="w-20 h-14 rounded-xl bg-black/40 overflow-hidden relative shrink-0 border border-white/5">
                  <img
                    src={ep.stillUrl || series.posterUrl}
                    alt={ep.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                  <div className="absolute inset-0 bg-black/30 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Play className="w-5 h-5 text-white fill-current" />
                  </div>
                </div>

                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-mono font-bold text-[#6B4FE0]">
                      EP {ep.episodeNumber}
                    </span>
                    <h4 className="text-xs font-bold text-white truncate group-hover:text-[#1FCFAE]">
                      {ep.title}
                    </h4>
                  </div>
                  <p className="text-[11px] text-[#A8A6C0] line-clamp-1 mt-0.5">
                    {ep.overview}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3 pl-4">
                <span className="text-[11px] font-mono text-[#A8A6C0] flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {ep.durationMinutes} min
                </span>
                <button className="w-8 h-8 rounded-lg bg-[#6B4FE0]/20 text-[#6B4FE0] group-hover:bg-[#6B4FE0] group-hover:text-white flex items-center justify-center transition-colors">
                  <Play className="w-3.5 h-3.5 fill-current ml-0.5" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
