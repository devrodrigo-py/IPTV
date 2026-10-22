import React from 'react';
import { Heart, Tv, Play, Trash2 } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';

export const FavoritesView: React.FC = () => {
  const { filteredChannels, favorites, setActiveTab } = useApp();

  const favoriteChannels = filteredChannels.filter((c) => favorites.includes(c.id));

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 select-none">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-[#FF6F91] fill-current" />
            <h1 className="text-xl font-bold text-white tracking-tight">Meus Favoritos</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            {favoriteChannels.length} canal(is) marcados com estrela/coração para acesso rápido.
          </p>
        </div>
      </div>

      {favoriteChannels.length > 0 ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {favoriteChannels.map((ch, idx) => (
            <ChannelCard key={ch.id} channel={ch} index={idx} />
          ))}
        </div>
      ) : (
        <div className="p-16 text-center bg-[#16162A]/40 rounded-3xl border border-[#2A2A45] mt-6">
          <Heart className="w-14 h-14 text-[#FF6F91]/40 mx-auto mb-3" />
          <h3 className="text-base font-bold text-white">Nenhum canal favorito ainda</h3>
          <p className="text-xs text-[#A8A6C0] max-w-sm mx-auto mt-1 mb-6">
            Clique no ícone de coração em qualquer canal da grade para adicioná-lo à sua lista rápida.
          </p>
          <button
            onClick={() => setActiveTab('channels')}
            className="px-5 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs cursor-pointer shadow-lg shadow-[#6B4FE0]/30 transition-all"
          >
            Navegar pelos Canais
          </button>
        </div>
      )}
    </div>
  );
};
