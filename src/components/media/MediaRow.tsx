import React from 'react';
import { ChevronRight } from 'lucide-react';

interface MediaRowProps {
  title: string;
  icon?: React.ReactNode;
  onSeeAll?: () => void;
  seeAllLabel?: string;
  /** Card width class, e.g. 'w-36' for posters, 'w-64' for landscape. */
  itemWidth?: string;
  children: React.ReactNode;
}

/** Horizontal, scrollable row of cards (the classic streaming-home shelf). */
export const MediaRow: React.FC<MediaRowProps> = ({ title, icon, onSeeAll, seeAllLabel = 'Ver tudo', itemWidth = 'w-36 md:w-40', children }) => {
  const items = React.Children.toArray(children);
  if (items.length === 0) return null;
  return (
    <section className="space-y-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          {icon}
          <h2 className="text-base font-bold text-white tracking-wide">{title}</h2>
        </div>
        {onSeeAll && (
          <button
            onClick={onSeeAll}
            data-tv-title={`${seeAllLabel}: ${title}`}
            className="tv-card text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-medium flex items-center gap-1 cursor-pointer px-2 py-1 rounded-lg focus:outline-none"
          >
            {seeAllLabel} <ChevronRight className="w-3.5 h-3.5" />
          </button>
        )}
      </div>
      <div className="flex gap-4 overflow-x-auto pb-3 pt-1 px-1 -mx-1 scrollbar-none scroll-smooth">
        {items.map((child, i) => (
          <div key={i} className={`${itemWidth} shrink-0`}>
            {child}
          </div>
        ))}
      </div>
    </section>
  );
};
