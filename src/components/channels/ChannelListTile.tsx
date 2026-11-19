import React from 'react';
import { Tv, Heart, Play, Radio } from 'lucide-react';
import { Channel } from '../../types';
import { useApp } from '../../context/AppContext';

interface ChannelListTileProps {
  channel: Channel;
  index: number;
}

export const ChannelListTile: React.FC<ChannelListTileProps> = ({ channel, index }) => {
  const { playChannel, isFavorite, toggleFavorite, getChannelCurrentProgram } = useApp();

  const currentProgram = getChannelCurrentProgram(channel.id);
  const isFav = isFavorite(channel.id);

  return (
    <div
      onClick={() => playChannel(channel)}
      tabIndex={0}
      data-tv-title={`Canal: ${channel.name}`}
      onKeyDown={(e) => {
        if (e.key === 'Enter') { e.preventDefault(); playChannel(channel); }
      }}
      className="tv-card group flex items-center justify-between p-3.5 rounded-2xl bg-[#141418] hover:bg-[#1E1E24] border border-[#2A2A31]/60 hover:border-[#7C5CFF]/50 transition-all cursor-pointer shadow-sm hover:shadow-lg focus:outline-none"
    >
      <div className="flex items-center gap-4 min-w-0 flex-1">
        <span className="text-xs font-mono font-bold text-[#A1A1AA] w-7 text-center">
          {(index + 1).toString().padStart(2, '0')}
        </span>

        <div className="w-12 h-12 rounded-xl bg-black/30 p-1 flex items-center justify-center shrink-0 border border-white/5 relative overflow-hidden">
          {channel.logoUrl ? (
            <img
              src={channel.logoUrl}
              alt={channel.name}
              className="max-h-9 max-w-full object-contain"
              onError={(e) => {
                (e.target as HTMLElement).style.display = 'none';
              }}
            />
          ) : (
            <Tv className="w-6 h-6 text-[#7C5CFF]" />
          )}
        </div>

        <div className="min-w-0 flex-1 pr-4">
          <div className="flex items-center gap-2">
            <h4 className="font-bold text-sm text-white truncate group-hover:text-[#F5F5F7]">
              {channel.name}
            </h4>
            {channel.resolution && (
              <span
                className={`text-[9px] font-bold px-1.5 py-0.2 rounded uppercase ${
                  channel.resolution === '4K'
                    ? 'bg-[#FF6F91]/20 text-[#FF6F91]'
                    : 'bg-[#22D3A6]/20 text-[#22D3A6]'
                }`}
              >
                {channel.resolution}
              </span>
            )}
          </div>

          {currentProgram ? (
            <p className="text-xs text-[#22D3A6] truncate mt-0.5 font-medium flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#22D3A6] animate-ping" />
              {currentProgram.title}
            </p>
          ) : (
            <p className="text-xs text-[#A1A1AA] truncate mt-0.5">
              {channel.groupTitle || 'Canal Geral'}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button
          onClick={(e) => {
            e.stopPropagation();
            toggleFavorite(channel.id);
          }}
          className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all cursor-pointer ${
            isFav
              ? 'bg-[#FF6F91]/20 text-[#FF6F91]'
              : 'text-[#A1A1AA] hover:text-[#FF6F91] hover:bg-white/10'
          }`}
        >
          <Heart className="w-4 h-4" fill={isFav ? '#FF6F91' : 'none'} />
        </button>

        <button
          onClick={() => playChannel(channel)}
          className="w-9 h-9 rounded-xl bg-[#7C5CFF] hover:bg-[#7C5CFF]/80 text-white flex items-center justify-center transition-transform group-hover:scale-105 cursor-pointer"
        >
          <Play className="w-4 h-4 fill-current ml-0.5" />
        </button>
      </div>
    </div>
  );
};
