import React from 'react';
import { ChevronRight } from 'lucide-react';
import { useApp } from '../../context/AppContext';

interface MediaRowProps {
  title: string;
  /** Kept for compatibility; rows show no icons in the premium layout. */
  icon?: React.ReactNode;
  onSeeAll?: () => void;
  seeAllLabel?: string;
  /** Card width class, e.g. 'w-40' for posters, 'w-72' for landscape tiles. */
  itemWidth?: string;
  children: React.ReactNode;
}

/** Horizontal shelf. Generous vertical padding leaves room for the focus zoom. */
export const MediaRow: React.FC<MediaRowProps> = ({ title, onSeeAll, seeAllLabel = 'Ver tudo', itemWidth = 'w-32 md:w-36', children }) => {
  const { tvMode } = useApp();
  const items = React.Children.toArray(children);
  if (items.length === 0) return null;
  return (
    <section className="relative">
      <div className="flex items-end justify-between px-1">
        <h2 className="font-display text-[22px] font-semibold text-white tracking-tight">{title}</h2>
        {onSeeAll && !tvMode && (
          <button
            onClick={onSeeAll}
            // Remote users reach the full list from the menu; this keeps D-pad moves row-to-row.
            data-tv-skip
            tabIndex={-1}
            className="text-sm text-[#8E8E99] hover:text-white font-medium flex items-center gap-1 cursor-pointer"
          >
            {seeAllLabel} <ChevronRight className="w-4 h-4" />
          </button>
        )}
      </div>
      <div data-shelf className="flex gap-4 overflow-x-auto scrollbar-none scroll-smooth py-5 px-3 -mx-3">
        {items.map((child, i) => (
          <div key={i} className={`${itemWidth} shrink-0`}>
            {child}
          </div>
        ))}
      </div>
    </section>
  );
};
