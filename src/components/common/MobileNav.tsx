import React from 'react';
import { Home, Tv2, Heart, FolderGit2, Settings, LayoutGrid } from 'lucide-react';
import { useApp, TabType } from '../../context/AppContext';

export const MobileNav: React.FC = () => {
  const { activeTab, setActiveTab } = useApp();

  const items: { id: TabType; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
    { id: 'home', label: 'Início', icon: Home },
    { id: 'channels', label: 'Canais', icon: Tv2 },
    { id: 'multiview', label: 'Multi', icon: LayoutGrid },
    { id: 'favorites', label: 'Favoritos', icon: Heart },
    { id: 'playlists', label: 'Listas', icon: FolderGit2 },
    { id: 'settings', label: 'Ajustes', icon: Settings },
  ];

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-[#07070F]/95 backdrop-blur-xl border-t border-[#2A2A45] flex items-center justify-around px-2 z-30">
      {items.map((item) => {
        const isActive = activeTab === item.id;
        const Icon = item.icon;
        return (
          <button
            key={item.id}
            onClick={() => setActiveTab(item.id)}
            className={`flex flex-col items-center justify-center flex-1 py-1 transition-all cursor-pointer ${
              isActive ? 'text-[#6B4FE0]' : 'text-[#A8A6C0] hover:text-white'
            }`}
          >
            <Icon className="w-5 h-5 mb-1" />
            <span className="text-[10px] font-medium tracking-tight">{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
};
