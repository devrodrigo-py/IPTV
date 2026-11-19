import React, { useState } from 'react';
import { Film, Play, Star, Tv } from 'lucide-react';

// Hover follows the pointer only when the user is actually using a mouse:
// scrolling with the remote moves cards under a resting pointer and would
// otherwise fire mouseenter on whatever card passes beneath it.
let lastKeyAt = 0;
if (typeof window !== 'undefined') {
  window.addEventListener('keydown', () => (lastKeyAt = Date.now()), true);
}
const pointerActive = () => Date.now() - lastKeyAt > 1200;

interface PosterCardProps {
  title: string;
  imageUrl?: string;
  subtitle?: string;
  rating?: number;
  /** 0..1 watched fraction; shows a progress bar when > 0. */
  progress?: number;
  aspect?: 'poster' | 'landscape' | 'logo';
  badge?: string;
  tvTitle?: string;
  onSelect: () => void;
  /** Called once the card is first shown or focused (lazy artwork lookups). */
  onVisible?: () => void;
  /** Called when the card receives focus (drives the Home billboard). */
  onFocused?: () => void;
  className?: string;
}

/**
 * One card for movies, series, episodes and history entries. Images load
 * lazily and fall back to the title when the provider sends a broken URL.
 */
export const PosterCard: React.FC<PosterCardProps> = ({
  title,
  imageUrl,
  subtitle,
  rating,
  progress,
  aspect = 'poster',
  badge,
  tvTitle,
  onSelect,
  onVisible,
  onFocused,
  className = '',
}) => {
  const [broken, setBroken] = useState(false);
  const showImage = !!imageUrl && !broken;
  const aspectClass = aspect === 'poster' ? 'aspect-[2/3]' : 'aspect-video';

  return (
    <div
      tabIndex={0}
      role="button"
      data-tv-title={tvTitle || title}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter') { e.preventDefault(); onSelect(); }
      }}
      onFocus={(e) => {
        onVisible?.();
        onFocused?.();
        // Keep the focused card inside horizontally scrolling rows.
        e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }}
      onMouseEnter={() => {
        if (!pointerActive()) return;
        onVisible?.();
        onFocused?.();
      }}
      className={`tv-card group relative bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0]/60 overflow-hidden cursor-pointer flex flex-col transition-all duration-200 focus:outline-none ${className}`}
    >
      <div className={`relative ${aspectClass} w-full bg-gradient-to-br from-[#1E1E38] to-[#0B0B18] overflow-hidden`}>
        {showImage ? (
          <img
            src={imageUrl}
            alt=""
            loading="lazy"
            decoding="async"
            onError={() => setBroken(true)}
            className={`absolute inset-0 w-full h-full ${aspect === 'logo' ? 'object-contain p-4' : 'object-cover'} group-hover:scale-105 transition-transform duration-300`}
          />
        ) : (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-3 text-center gap-2">
            {aspect === 'logo' ? <Tv className="w-8 h-8 text-[#6B4FE0]" /> : <Film className="w-8 h-8 text-[#6B4FE0]/70" />}
            <span className="text-xs font-bold text-white/90 line-clamp-3">{title}</span>
          </div>
        )}

        {!!rating && rating > 0 && (
          <div className="absolute top-2 right-2 px-1.5 py-0.5 rounded-md bg-black/75 text-[10px] font-bold text-[#FF6F91] flex items-center gap-1">
            <Star className="w-3 h-3 fill-current" />
            {rating.toFixed(1)}
          </div>
        )}
        {badge && (
          <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded-md bg-[#6B4FE0]/90 text-[10px] font-bold text-white">{badge}</div>
        )}

        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
          <div className="w-11 h-11 rounded-full bg-[#6B4FE0] text-white flex items-center justify-center">
            <Play className="w-5 h-5 fill-current ml-0.5" />
          </div>
        </div>

        {progress !== undefined && progress > 0 && (
          <div className="absolute bottom-0 left-0 right-0 h-1.5 bg-black/60">
            <div className="h-full bg-[#FF5468]" style={{ width: `${Math.round(progress * 100)}%` }} />
          </div>
        )}
      </div>

      <div className="p-2.5 min-w-0">
        <h3 className="font-bold text-xs text-white truncate group-hover:text-[#1FCFAE]">{title}</h3>
        {subtitle && <p className="text-[11px] text-[#A8A6C0] truncate mt-0.5">{subtitle}</p>}
      </div>
    </div>
  );
};
