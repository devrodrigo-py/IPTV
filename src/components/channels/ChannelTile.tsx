import { focusIntoView } from '../media/focusIntoView';
import React, { useState } from 'react';
import { Tv } from 'lucide-react';
import { Channel } from '../../types';
import { useApp } from '../../context/AppContext';

function hhmm(iso: string) {
  const d = new Date(iso);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

interface ChannelTileProps {
  channel: Channel;
  number?: number;
  onFocused?: () => void;
}

/**
 * Live channel tile: the logo on a dark 16:9 plate, then what is on air with
 * its progress. No badges or buttons: the remote's OK plays the channel.
 */
export const ChannelTile: React.FC<ChannelTileProps> = ({ channel, number, onFocused }) => {
  const { playChannel, getChannelCurrentProgram, isFavorite } = useApp();
  const [broken, setBroken] = useState(false);
  const now = getChannelCurrentProgram(channel.id);
  let pct = 0;
  if (now) {
    const s = Date.parse(now.startUtc);
    const e = Date.parse(now.endUtc);
    pct = e > s ? Math.min(100, Math.max(0, ((Date.now() - s) / (e - s)) * 100)) : 0;
  }

  return (
    <div
      tabIndex={0}
      role="button"
      aria-label={channel.name}
      data-tv-title={`Canal: ${channel.name}`}
      onClick={() => playChannel(channel)}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          playChannel(channel);
        }
      }}
      onFocus={(e) => {
        onFocused?.();
        focusIntoView(e.currentTarget);
      }}
      className="tv-card group rounded-lg overflow-hidden cursor-pointer bg-[#141418] focus:outline-none"
    >
      <div className="relative aspect-video w-full bg-gradient-to-br from-[#1C1C22] to-[#0E0E12]">
        {channel.logoUrl && !broken ? (
          <img
            src={channel.logoUrl}
            alt=""
            loading="lazy"
            decoding="async"
            onError={() => setBroken(true)}
            className="absolute inset-0 w-full h-full object-contain p-[16%]"
          />
        ) : (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 px-4">
            <Tv className="w-8 h-8 text-white/20" strokeWidth={1.4} />
            <span className="font-display font-bold text-white/80 text-center text-base leading-tight line-clamp-2">{channel.name}</span>
          </div>
        )}
        <span className="absolute top-2 left-2 flex items-center gap-1.5 px-1.5 py-0.5 rounded bg-black/60 text-[10px] font-bold tracking-wider text-white">
          <span className="w-1.5 h-1.5 rounded-full bg-[#FF3B4E]" />
          AO VIVO
        </span>
        {number !== undefined && (
          <span className="absolute top-2 right-2 text-[11px] font-mono font-semibold text-white/60">{number.toString().padStart(2, '0')}</span>
        )}
        {isFavorite(channel.id) && <span className="absolute bottom-2 right-2 text-[#FF4D8D] text-sm" aria-label="Favorito">♥</span>}
      </div>
      <div className="px-3 py-2.5">
        <p className="text-white text-sm font-semibold truncate">{channel.name}</p>
        <p className="text-[#8E8E99] text-xs truncate mt-0.5">{now ? `${hhmm(now.startUtc)} · ${now.title}` : channel.groupTitle || 'Ao vivo'}</p>
        <div className="mt-2 h-[3px] rounded-full bg-white/10 overflow-hidden">
          {pct > 0 && <div className="h-full bg-white/80" style={{ width: `${pct}%` }} />}
        </div>
      </div>
    </div>
  );
};
