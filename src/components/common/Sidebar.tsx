import nebulaIcon from '../../../assets/branding/nebula_icon.png';
import React from 'react';
import {
  Home,
  Tv2,
  Film,
  Tv,
  Heart,
  History,
  FolderGit2,
  Calendar,
  LayoutGrid,
  BarChart3,
  Settings,
  Sparkles,
  Search,
  Plus,
} from 'lucide-react';
import { useApp, TabType } from '../../context/AppContext';

interface NavItemConfig {
  id: TabType;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
  accent?: 'violet' | 'teal' | 'coral';
}

export const Sidebar: React.FC = () => {
  const { activeTab, setActiveTab, favorites, filteredChannels, setIsWrappedOpen, tvMode, myList } = useApp();
  // TV: a slim icon rail that expands over the content when it receives focus.
  const rail = tvMode;
  const label = rail ? 'hidden group-focus-within/aside:inline group-hover/aside:inline whitespace-nowrap' : '';

  const navItems: NavItemConfig[] = [
    { id: 'home', label: 'Início', icon: Home },
    { id: 'search', label: 'Buscar', icon: Search },
    { id: 'mylist', label: 'Minha lista', icon: Plus, badge: myList.length > 0 ? `${myList.length}` : undefined },
    { id: 'channels', label: 'Ao vivo', icon: Tv2, badge: `${filteredChannels.length}` },
    { id: 'vod', label: 'Filmes', icon: Film },
    { id: 'series', label: 'Séries', icon: Tv },
    { id: 'favorites', label: 'Favoritos', icon: Heart, badge: favorites.length > 0 ? `${favorites.length}` : undefined, accent: 'coral' },
    { id: 'history', label: 'Histórico', icon: History },
    { id: 'epg', label: 'Guia', icon: Calendar },
    { id: 'playlists', label: 'Minhas listas', icon: FolderGit2 },
    { id: 'multiview', label: 'Multiview', icon: LayoutGrid, accent: 'teal' },
    { id: 'stats', label: 'Estatísticas', icon: BarChart3 },
    { id: 'settings', label: 'Configurações', icon: Settings },
  ];

  const aside = (
    <aside
      className={`group/aside bg-[#07070F] border-r border-[#2A2A45]/60 flex flex-col h-screen select-none shrink-0 ${
        rail
          ? 'absolute inset-y-0 left-0 z-40 w-20 focus-within:w-72 hover:w-72 transition-[width] duration-200 focus-within:shadow-[24px_0_60px_rgba(0,0,0,0.75)]'
          : 'w-64'
      }`}
    >
      {/* Brand Logo Header */}
      <div className="h-16 px-5 flex items-center gap-3 border-b border-[#2A2A45]/40">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#6B4FE0] via-[#2A1D6B] to-[#1FCFAE] flex items-center justify-center shadow-lg shadow-[#6B4FE0]/25 overflow-hidden p-1.5">
          <img
            src={nebulaIcon}
            alt="Nebula"
            className="w-full h-full object-contain filter drop-shadow"
            onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        </div>
        <div className={rail ? 'hidden group-focus-within/aside:block group-hover/aside:block' : ''}>
          <span className="font-extrabold text-lg tracking-tight bg-gradient-to-r from-white via-[#F5F3FF] to-[#A8A6C0] bg-clip-text text-transparent font-['Outfit']">
            NEBULA <span className="text-[#1FCFAE] text-xs font-mono font-bold ml-0.5">IPTV</span>
          </span>
          <p className="text-[10px] text-[#A8A6C0] font-medium tracking-wider uppercase">
            Streaming Hub v3.0
          </p>
        </div>
      </div>

      {/* Nav items list */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive = activeTab === item.id;
          const Icon = item.icon;

          return (
            <button
              key={item.id}
              data-tv-title={`Menu: ${item.label}`}
              data-active={isActive ? 'true' : undefined}
              onClick={() => {
                setActiveTab(item.id);
                // TV: choosing a section hands focus to its content and folds the rail.
                if (rail) (document.activeElement as HTMLElement | null)?.blur();
              }}
              className={`tv-card w-full flex items-center justify-between rounded-xl font-medium ${rail ? 'px-4 py-3 text-sm' : 'px-3.5 py-2.5 text-xs'} transition-all cursor-pointer group focus:outline-none ${
                isActive
                  ? 'bg-[#16162A] text-white font-semibold shadow-inner border border-[#6B4FE0]/30'
                  : 'text-[#A8A6C0] hover:text-[#F5F3FF] hover:bg-[#16162A]/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <div
                  className={`p-1.5 rounded-lg transition-colors ${
                    isActive
                      ? item.accent === 'coral'
                        ? 'bg-[#FF6F91]/20 text-[#FF6F91]'
                        : item.accent === 'teal'
                        ? 'bg-[#1FCFAE]/20 text-[#1FCFAE]'
                        : 'bg-[#6B4FE0]/20 text-[#6B4FE0]'
                      : 'text-[#A8A6C0] group-hover:text-white'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                </div>
                <span className={label}>{item.label}</span>
              </div>

              {item.badge && !rail && (
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-mono font-bold ${
                    isActive
                      ? 'bg-[#6B4FE0] text-white'
                      : 'bg-[#2A2A45] text-[#A8A6C0] group-hover:text-white'
                  }`}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Nebula Wrapped Promotional Card in Footer */}
      <div className={`p-4 border-t border-[#2A2A45]/40 ${rail ? 'hidden' : ''}`}>
        <div
          tabIndex={0}
          data-tv-title="Especial: Nebula Wrapped 2026"
          onClick={() => setIsWrappedOpen(true)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') { e.preventDefault(); setIsWrappedOpen(true); }
          }}
          className="tv-card p-3.5 rounded-2xl bg-gradient-to-br from-[#16162A] via-[#1E1E38] to-[#2A1D6B]/40 border border-[#6B4FE0]/30 hover:border-[#6B4FE0]/70 transition-all cursor-pointer group shadow-lg focus:outline-none"
        >
          <div className="flex items-center gap-2 mb-1">
            <Sparkles className="w-4 h-4 text-[#FF6F91] group-hover:rotate-12 transition-transform" />
            <h4 className="text-xs font-bold text-white">Nebula Wrapped 2026</h4>
          </div>
          <p className="text-[11px] text-[#A8A6C0] leading-snug">
            Descubra suas estatísticas cósmicas e canais favoritos.
          </p>
        </div>
      </div>
    </aside>
  );

  return rail ? <div className="relative w-20 h-screen shrink-0">{aside}</div> : aside;
};
