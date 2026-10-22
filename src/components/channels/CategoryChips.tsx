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
        data-tv-title="Categoria: Todos os Canais"
        className={`tv-card px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer focus:outline-none ${
          selectedCategory === 'all'
            ? 'bg-[#6B4FE0] text-white shadow-lg shadow-[#6B4FE0]/30'
            : 'bg-[#16162A] text-[#A8A6C0] hover:text-white hover:bg-[#1E1E38] border border-[#2A2A45]'
        }`}
      >
        Todos os Canais
      </button>

      {categories.map((cat) => {
        const isSelected = selectedCategory === cat;
        return (
          <button
            key={cat}
            data-tv-title={`Categoria: ${cat}`}
            onClick={() => onSelectCategory(cat)}
            className={`tv-card px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer focus:outline-none ${
              isSelected
                ? 'bg-[#6B4FE0] text-white shadow-lg shadow-[#6B4FE0]/30'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white hover:bg-[#1E1E38] border border-[#2A2A45]'
            }`}
          >
            {cat}
          </button>
        );
      })}
    </div>
  );
};
