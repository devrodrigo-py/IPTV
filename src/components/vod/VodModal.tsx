import React from 'react';
import { X, Play, Star, Clock, Calendar, Film, User } from 'lucide-react';
import { VodItem } from '../../types';
import { useApp } from '../../context/AppContext';

interface VodModalProps {
  vod: VodItem;
  onClose: () => void;
}

export const VodModal: React.FC<VodModalProps> = ({ vod, onClose }) => {
  const { playVod } = useApp();

  return (
    <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-2xl bg-[#16162A] border border-[#2A2A45] rounded-3xl overflow-hidden shadow-2xl relative animate-in zoom-in-95 duration-200">
        {/* Close Button */}
        <button
          onClick={onClose}
          tabIndex={0}
          data-tv-title="Fechar Detalhes do Filme"
          className="tv-card absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-black/80 text-white flex items-center justify-center cursor-pointer transition-colors focus:outline-none"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Backdrop Banner */}
        <div className="relative h-64 w-full bg-black">
          <img
            src={vod.backdropUrl || vod.posterUrl}
            alt={vod.title}
            className="w-full h-full object-cover opacity-60"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[#16162A] via-[#16162A]/40 to-transparent" />

          {/* Quick Play Floating Button */}
          <button
            onClick={() => playVod(vod)}
            tabIndex={0}
            autoFocus
            data-tv-title={`Assistir ${vod.title}`}
            className="tv-card absolute bottom-6 left-6 px-6 py-3 rounded-2xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-sm flex items-center gap-2.5 shadow-xl shadow-[#6B4FE0]/40 transition-transform active:scale-95 cursor-pointer focus:outline-none"
          >
            <Play className="w-5 h-5 fill-current" />
            Assistir Filme Agora
          </button>
        </div>

        {/* Content Details */}
        <div className="p-6 pt-2 space-y-4">
          <div>
            <div className="flex items-center gap-3 text-xs text-[#A8A6C0] mb-1.5">
              <span className="flex items-center gap-1 text-[#FF6F91] font-bold">
                <Star className="w-3.5 h-3.5 fill-current" />
                {vod.rating} / 10
              </span>
              <span>•</span>
              <span className="flex items-center gap-1">
                <Calendar className="w-3.5 h-3.5" />
                {vod.year}
              </span>
              <span>•</span>
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                {vod.durationMinutes} min
              </span>
              <span>•</span>
              <span className="px-2 py-0.5 rounded-md bg-[#6B4FE0]/20 text-[#6B4FE0] font-semibold">
                {vod.category}
              </span>
            </div>

            <h2 className="text-2xl font-black text-white">{vod.title}</h2>
          </div>

          <p className="text-xs text-[#A8A6C0] leading-relaxed">
            {vod.description}
          </p>

          <div className="pt-2 border-t border-[#2A2A45]/60 grid grid-cols-2 gap-4 text-xs">
            {vod.director && (
              <div>
                <span className="text-[#A8A6C0] block text-[10px] uppercase font-bold tracking-wider">
                  Direção
                </span>
                <span className="text-white font-medium">{vod.director}</span>
              </div>
            )}
            {vod.cast && vod.cast.length > 0 && (
              <div>
                <span className="text-[#A8A6C0] block text-[10px] uppercase font-bold tracking-wider">
                  Elenco Principal
                </span>
                <span className="text-white font-medium">{vod.cast.join(', ')}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
