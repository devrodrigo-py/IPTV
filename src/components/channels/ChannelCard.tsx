import React from 'react';
import { Tv, Heart, Play, Radio } from 'lucide-react';
import { Channel } from '../../types';
import { useApp } from '../../context/AppContext';

interface ChannelCardProps {
  channel: Channel;
  index?: number;
}

export const ChannelCard: React.FC<ChannelCardProps> = ({ channel, index }) => {
  const { playChannel, isFavorite, toggleFavorite, getChannelCurrentProgram } = useApp();

  const currentProgram = getChannelCurrentProgram(channel.id);
  const isFav = isFavorite(channel.id);

  // Calculate EPG progress percentage if current program exists
  let progressPct = 0;
  if (currentProgram) {
    const start = new Date(currentProgram.startUtc).getTime();
    const end = new Date(currentProgram.endUtc).getTime();
    const now = Date.now();
    if (end > start) {
      progressPct = Math.min(100, Math.max(0, ((now - start) / (end - start)) * 100));
    }
  }

  return (
    <div
      onClick={() => playChannel(channel)}
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter') playChannel(channel);
      }}
      className="tv-card group relative bg-[#16162A] hover:bg-[#1E1E38] rounded-2xl border border-[#2A2A45]/70 hover:border-[#6B4FE0]/60 p-4 transition-all duration-200 cursor-pointer flex flex-col justify-between overflow-hidden shadow-md hover:shadow-xl hover:shadow-[#6B4FE0]/10"
    >
      {/* Top row: Number, Resolution, Favorite */}
      <div className="flex items-center justify-between mb-3 z-10">
        <div className="flex items-center gap-2">
          {index !== undefined && (
            <span className="text-[11px] font-mono font-bold text-[#A8A6C0]/70 bg-black/30 px-2 py-0.5 rounded-md">
              {(index + 1).toString().padStart(2, '0')}
            </span>
          )}
          {channel.resolution && (
            <span
              className={`text-[10px] font-bold px-2 py-0.5 rounded-md uppercase tracking-wider ${
                channel.resolution === '4K'
                  ? 'bg-[#FF6F91]/20 text-[#FF6F91] border border-[#FF6F91]/40'
                  : 'bg-[#1FCFAE]/20 text-[#1FCFAE] border border-[#1FCFAE]/40'
              }`}
            >
              {channel.resolution}
            </span>
          )}
        </div>

        <button
          onClick={(e) => {
            e.stopPropagation();
            toggleFavorite(channel.id);
          }}
          className={`w-8 h-8 rounded-xl flex items-center justify-center transition-all cursor-pointer ${
            isFav
              ? 'bg-[#FF6F91]/20 text-[#FF6F91]'
              : 'text-[#A8A6C0] hover:text-[#FF6F91] hover:bg-white/10'
          }`}
          title={isFav ? 'Remover dos favoritos' : 'Adicionar aos favoritos'}
        >
          <Heart className="w-4 h-4" fill={isFav ? '#FF6F91' : 'none'} />
        </button>
      </div>

      {/* Center: Logo with hover play overlay */}
      <div className="relative my-2 h-24 flex items-center justify-center rounded-xl bg-black/25 p-2 overflow-hidden border border-white/5">
        {channel.logoUrl ? (
          <img
            src={channel.logoUrl}
            alt={channel.name}
            className="max-h-16 max-w-full object-contain filter drop-shadow group-hover:scale-105 transition-transform duration-300"
            onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        ) : (
          <Tv className="w-10 h-10 text-[#6B4FE0]/60 group-hover:scale-110 transition-transform" />
        )}

        {/* Hover Play Button */}
        <div className="absolute inset-0 bg-[#07070F]/60 backdrop-blur-[1px] opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity duration-200">
          <div className="w-11 h-11 rounded-full bg-[#6B4FE0] text-white flex items-center justify-center shadow-lg shadow-[#6B4FE0]/50 transform group-hover:scale-105 transition-transform">
            <Play className="w-5 h-5 fill-current ml-0.5" />
          </div>
        </div>
      </div>

      {/* Bottom: Info & EPG progress */}
      <div className="z-10 mt-2">
        <h3 className="font-bold text-sm text-white truncate group-hover:text-[#F5F3FF] transition-colors">
          {channel.name}
        </h3>

        {currentProgram ? (
          <div className="mt-1">
            <p className="text-xs text-[#1FCFAE] font-medium truncate flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#1FCFAE] animate-pulse" />
              {currentProgram.title}
            </p>
            {/* EPG progress bar */}
            <div className="w-full bg-[#2A2A45] h-1 rounded-full mt-1.5 overflow-hidden">
              <div
                className="bg-gradient-to-r from-[#6B4FE0] to-[#1FCFAE] h-full rounded-full transition-all duration-300"
                style={{ width: `${progressPct}%` }}
              />
            </div>
          </div>
        ) : (
          <p className="text-xs text-[#A8A6C0] truncate mt-1">
            {channel.groupTitle || 'Canal Geral'}
          </p>
        )}
      </div>
    </div>
  );
};
