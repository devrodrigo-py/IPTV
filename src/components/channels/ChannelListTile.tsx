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
      onKeyDown={(e) => {
        if (e.key === 'Enter') playChannel(channel);
      }}
      className="tv-card group flex items-center justify-between p-3.5 rounded-2xl bg-[#16162A] hover:bg-[#1E1E38] border border-[#2A2A45]/60 hover:border-[#6B4FE0]/50 transition-all cursor-pointer shadow-sm hover:shadow-lg"
    >
      <div className="flex items-center gap-4 min-w-0 flex-1">
        <span className="text-xs font-mono font-bold text-[#A8A6C0] w-7 text-center">
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
            <Tv className="w-6 h-6 text-[#6B4FE0]" />
          )}
        </div>

        <div className="min-w-0 flex-1 pr-4">
          <div className="flex items-center gap-2">
            <h4 className="font-bold text-sm text-white truncate group-hover:text-[#F5F3FF]">
              {channel.name}
            </h4>
            {channel.resolution && (
              <span
                className={`text-[9px] font-bold px-1.5 py-0.2 rounded uppercase ${
                  channel.resolution === '4K'
                    ? 'bg-[#FF6F91]/20 text-[#FF6F91]'
                    : 'bg-[#1FCFAE]/20 text-[#1FCFAE]'
                }`}
              >
                {channel.resolution}
              </span>
            )}
          </div>

          {currentProgram ? (
            <p className="text-xs text-[#1FCFAE] truncate mt-0.5 font-medium flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-[#1FCFAE] animate-ping" />
              {currentProgram.title}
            </p>
          ) : (
            <p className="text-xs text-[#A8A6C0] truncate mt-0.5">
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
              : 'text-[#A8A6C0] hover:text-[#FF6F91] hover:bg-white/10'
          }`}
        >
          <Heart className="w-4 h-4" fill={isFav ? '#FF6F91' : 'none'} />
        </button>

        <button
          onClick={() => playChannel(channel)}
          className="w-9 h-9 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white flex items-center justify-center transition-transform group-hover:scale-105 cursor-pointer"
        >
          <Play className="w-4 h-4 fill-current ml-0.5" />
        </button>
      </div>
    </div>
  );
};
