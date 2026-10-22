import React, { useState } from 'react';
import {
  Tv2,
  LayoutGrid,
  List,
  Search,
  Filter,
  Radio,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { ChannelListTile } from '../components/channels/ChannelListTile';
import { CategoryChips } from '../components/channels/CategoryChips';

export const ChannelsView: React.FC = () => {
  const { filteredChannels, categories } = useApp();

  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [localSearch, setLocalSearch] = useState('');

  const displayChannels = filteredChannels.filter((c) => {
    if (selectedCategory !== 'all') {
      const g = (c.groupTitle || 'Geral').trim().toLowerCase();
      if (g !== selectedCategory.trim().toLowerCase()) return false;
    }
    if (localSearch.trim()) {
      const q = localSearch.toLowerCase();
      const matchName = c.name.toLowerCase().includes(q);
      const matchGroup = (c.groupTitle || '').toLowerCase().includes(q);
      if (!matchName && !matchGroup) return false;
    }
    return true;
  });

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Top Header & Layout Switcher */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <Tv2 className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Grade de Canais Ao Vivo</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            {displayChannels.length} de {filteredChannels.length} canais disponíveis
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Channel Name Search Filter */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-[#A8A6C0] absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Filtrar nesta lista..."
              value={localSearch}
              onChange={(e) => setLocalSearch(e.target.value)}
              className="bg-[#16162A] text-xs text-white placeholder-[#A8A6C0] pl-8 pr-3 py-1.5 rounded-xl border border-[#2A2A45] focus:border-[#6B4FE0] outline-none"
            />
          </div>

          {/* Grid / List Mode */}
          <div className="flex items-center bg-[#16162A] p-1 rounded-xl border border-[#2A2A45]">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'grid' ? 'bg-[#6B4FE0] text-white shadow' : 'text-[#A8A6C0] hover:text-white'
              }`}
              title="Modo Grade"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'list' ? 'bg-[#6B4FE0] text-white shadow' : 'text-[#A8A6C0] hover:text-white'
              }`}
              title="Modo Lista"
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Category Pills */}
      <CategoryChips
        categories={categories}
        selectedCategory={selectedCategory}
        onSelectCategory={setSelectedCategory}
      />

      {/* Channels Display */}
      {displayChannels.length > 0 ? (
        viewMode === 'grid' ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {displayChannels.map((ch, idx) => (
              <ChannelCard key={ch.id} channel={ch} index={idx} />
            ))}
          </div>
        ) : (
          <div className="space-y-2.5">
            {displayChannels.map((ch, idx) => (
              <ChannelListTile key={ch.id} channel={ch} index={idx} />
            ))}
          </div>
        )
      ) : (
        <div className="p-12 text-center bg-[#16162A]/50 rounded-3xl border border-[#2A2A45] mt-6">
          <Radio className="w-12 h-12 text-[#6B4FE0]/50 mx-auto mb-3" />
          <h3 className="text-base font-bold text-white">Nenhum canal encontrado</h3>
          <p className="text-xs text-[#A8A6C0] mt-1">
            Tente selecionar outra categoria ou ajuste o termo de busca.
          </p>
        </div>
      )}
    </div>
  );
};
