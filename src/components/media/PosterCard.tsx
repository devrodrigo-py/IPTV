import { focusIntoView } from './focusIntoView';
import React, { useState } from 'react';
import { Tv } from 'lucide-react';

// Hover follows the pointer only when the user is actually using a mouse:
// scrolling with the remote moves cards under a resting pointer and would
// otherwise fire mouseenter on whatever card passes beneath it.
let lastKeyAt = 0;
if (typeof window !== 'undefined') {
  window.addEventListener('keydown', () => (lastKeyAt = Date.now()), true);
}
const pointerActive = () => Date.now() - lastKeyAt > 1200;

/** Deep, desaturated duotones for titles without artwork (picked by title). */
const FALLBACKS = [
  ['#2B1F66', '#0E0B24'],
  ['#4A1630', '#14070E'],
  ['#0F3B3A', '#051414'],
  ['#3A2A10', '#120D05'],
  ['#1B2F55', '#070D1A'],
  ['#3B1550', '#10061A'],
];
function fallbackFor(title: string) {
  let h = 0;
  for (const ch of title) h = (h * 33 + ch.charCodeAt(0)) >>> 0;
  return FALLBACKS[h % FALLBACKS.length];
}

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
 * Art-first card for movies, series, episodes and channels. Posters show only
 * the artwork (the title appears in the billboard when focused); titles
 * without artwork get a typographic card instead of a broken image.
 */
export const PosterCard: React.FC<PosterCardProps> = ({
  title,
  imageUrl,
  subtitle,
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
  const [c1, c2] = fallbackFor(title);
  const showCaption = aspect !== 'poster';

  return (
    <div
      tabIndex={0}
      role="button"
      aria-label={title}
      data-tv-title={tvTitle || title}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          onSelect();
        }
      }}
      onFocus={(e) => {
        onVisible?.();
        onFocused?.();
        // Keep the focused card inside horizontally scrolling rows.
        focusIntoView(e.currentTarget);
      }}
      onMouseEnter={() => {
        if (!pointerActive()) return;
        onVisible?.();
        onFocused?.();
      }}
      className={`tv-card group relative rounded-lg overflow-hidden cursor-pointer bg-[#141418] focus:outline-none ${className}`}
    >
      <div className={`relative ${aspectClass} w-full overflow-hidden`}>
        {showImage ? (
          <img
            src={imageUrl}
            alt=""
            loading="lazy"
            decoding="async"
            onError={() => setBroken(true)}
            className={`absolute inset-0 w-full h-full ${aspect === 'logo' ? 'object-contain p-[14%]' : 'object-cover'}`}
          />
        ) : aspect === 'logo' ? (
          <div className="absolute inset-0 flex items-center justify-center">
            <Tv className="w-10 h-10 text-white/25" strokeWidth={1.4} />
          </div>
        ) : (
          <div
            className="absolute inset-0 flex flex-col justify-end p-4"
            style={{ background: `linear-gradient(160deg, ${c1} 0%, ${c2} 100%)` }}
          >
            <span className="font-display font-extrabold text-white leading-[1.05] text-[19px] line-clamp-4 drop-shadow">{title}</span>
            {subtitle && <span className="mt-1.5 text-[11px] uppercase tracking-[0.14em] text-white/55 line-clamp-1">{subtitle}</span>}
          </div>
        )}

        {/* Caption on landscape tiles (continue watching, channels) */}
        {showCaption && (showImage || aspect === 'logo') && (
          <div className="absolute inset-x-0 bottom-0 pt-10 pb-3 px-3 bg-gradient-to-t from-black/90 via-black/50 to-transparent">
            <p className="text-white text-sm font-semibold truncate">{title}</p>
            {subtitle && <p className="text-white/60 text-xs truncate mt-0.5">{subtitle}</p>}
          </div>
        )}

        {badge && (
          <span className="absolute top-2 left-2 px-2 py-0.5 rounded bg-black/70 text-[10px] font-bold uppercase tracking-wider text-white">
            {badge}
          </span>
        )}

        {progress !== undefined && progress > 0 && (
          <div className="absolute bottom-0 inset-x-0 h-1 bg-white/20">
            <div className="h-full bg-gradient-to-r from-[#7C5CFF] to-[#FF4D8D]" style={{ width: `${Math.round(progress * 100)}%` }} />
          </div>
        )}
      </div>
    </div>
  );
};
