import React from 'react';

interface CategoryChipsProps {
  categories: string[];
  selectedCategory: string;
  onSelectCategory: (cat: string) => void;
  allLabel?: string;
}

/** Pill filters (same style as the season selector). */
export const CategoryChips: React.FC<CategoryChipsProps> = ({ categories, selectedCategory, onSelectCategory, allLabel = 'Todos' }) => {
  const pill = (id: string, label: string) => (
    <button
      key={id}
      data-tv-title={`Categoria: ${label}`}
      onClick={() => onSelectCategory(id)}
      onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
      className={`tv-card shrink-0 h-10 px-5 rounded-full text-[15px] font-semibold whitespace-nowrap cursor-pointer focus:outline-none ${
        selectedCategory === id ? 'bg-white text-black' : 'bg-white/10 text-white/75 hover:bg-white/20'
      }`}
    >
      {label}
    </button>
  );
  return (
    <div className="flex items-center gap-2 overflow-x-auto scrollbar-none py-1.5 px-1 -mx-1 select-none">
      {pill('all', allLabel)}
      {categories.map((c) => pill(c, c))}
    </div>
  );
};
