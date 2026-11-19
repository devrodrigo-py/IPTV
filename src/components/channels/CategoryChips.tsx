import React from 'react';

interface CategoryChipsProps {
  categories: string[];
  selectedCategory: string;
  onSelectCategory: (cat: string) => void;
}

export const CategoryChips: React.FC<CategoryChipsProps> = ({
  categories,
  selectedCategory,
  onSelectCategory,
}) => {
  return (
    <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none select-none">
      <button
        onClick={() => onSelectCategory('all')}
        data-tv-title="Categoria: Todos"
        onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
        className={`tv-card px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer focus:outline-none ${
          selectedCategory === 'all'
            ? 'bg-[#7C5CFF] text-white shadow-lg shadow-[#7C5CFF]/30'
            : 'bg-[#141418] text-[#A1A1AA] hover:text-white hover:bg-[#1E1E24] border border-[#2A2A31]'
        }`}
      >
        Todos
      </button>

      {categories.map((cat) => {
        const isSelected = selectedCategory === cat;
        return (
          <button
            key={cat}
            data-tv-title={`Categoria: ${cat}`}
            onClick={() => onSelectCategory(cat)}
            onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
            className={`tv-card px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer focus:outline-none ${
              isSelected
                ? 'bg-[#7C5CFF] text-white shadow-lg shadow-[#7C5CFF]/30'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white hover:bg-[#1E1E24] border border-[#2A2A31]'
            }`}
          >
            {cat}
          </button>
        );
      })}
    </div>
  );
};
