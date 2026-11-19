import React from 'react';
import { Home, Search, Plus, Radio, Clapperboard, Tv, CalendarDays, LayoutGrid, type LucideIcon } from 'lucide-react';
import { useApp, TabType } from '../../context/AppContext';
import { NebulaLogo, NebulaMark } from '../brand/NebulaLogo';
import { Avatar } from '../profiles/Avatar';

interface NavItem {
  id: TabType;
  label: string;
  icon: LucideIcon;
}

/** Seven destinations, like the big streaming apps; everything else lives in "Mais". */
const NAV: NavItem[] = [
  { id: 'search', label: 'Buscar', icon: Search },
  { id: 'home', label: 'Início', icon: Home },
  { id: 'channels', label: 'Ao vivo', icon: Radio },
  { id: 'vod', label: 'Filmes', icon: Clapperboard },
  { id: 'series', label: 'Séries', icon: Tv },
  { id: 'mylist', label: 'Minha lista', icon: Plus },
  { id: 'epg', label: 'Guia', icon: CalendarDays },
];

const SECONDARY: TabType[] = ['more', 'playlists', 'favorites', 'history', 'multiview', 'stats', 'settings'];

export const Sidebar: React.FC = () => {
  const { activeTab, setActiveTab, tvMode, activeProfile, lockToProfileGate } = useApp();
  // TV: a slim icon rail that expands over the content when it receives focus.
  const rail = tvMode;
  // Hover only opens the rail where there is a real pointer; touch leaves a sticky :hover behind.
  const label = rail ? 'hidden group-focus-within/aside:inline [@media(hover:hover)]:group-hover/aside:inline whitespace-nowrap' : '';

  const go = (id: TabType) => {
    setActiveTab(id);
    // TV: choosing a section hands focus to its content and folds the rail.
    if (rail) (document.activeElement as HTMLElement | null)?.blur();
  };

  const item = (id: TabType, text: string, icon: React.ReactNode, active: boolean) => (
    <button
      key={id}
      data-tv-title={`Menu: ${text}`}
      data-active={active ? 'true' : undefined}
      onClick={() => go(id)}
      className={`tv-card relative w-full flex items-center rounded-xl cursor-pointer focus:outline-none transition-colors ${
        rail ? 'h-12 px-4 gap-5' : 'h-11 px-4 gap-4'
      } ${active ? 'text-white' : 'text-[#8E8E99] hover:text-white'}`}
    >
      {active && <span className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-6 rounded-full bg-[#7C5CFF]" aria-hidden />}
      {icon}
      <span className={`${label} ${rail ? 'text-[17px]' : 'text-sm'} ${active ? 'font-semibold' : 'font-medium'}`}>{text}</span>
    </button>
  );

  const aside = (
    <aside
      className={`group/aside flex flex-col h-screen select-none shrink-0 ${
        rail
          ? 'absolute inset-y-0 left-0 z-40 w-[84px] focus-within:w-80 [@media(hover:hover)]:hover:w-80 transition-[width] duration-200 bg-gradient-to-r from-[#060608] via-[#060608]/95 to-transparent focus-within:to-[#060608]/90 focus-within:shadow-[60px_0_120px_rgba(0,0,0,0.9)]'
          : 'w-64 bg-[#060608] border-r border-white/5'
      }`}
    >
      <div className={`flex items-center ${rail ? 'h-24 px-[22px]' : 'h-20 px-5'}`}>
        {rail ? (
          <>
            <span className="group-focus-within/aside:hidden [@media(hover:hover)]:group-hover/aside:hidden">
              <NebulaMark size={40} title="Nebula" />
            </span>
            <span className="hidden group-focus-within/aside:inline-flex [@media(hover:hover)]:group-hover/aside:inline-flex">
              <NebulaLogo size={36} />
            </span>
          </>
        ) : (
          <NebulaLogo size={30} />
        )}
      </div>

      {activeProfile && (
        <div className={rail ? 'px-3 mb-4' : 'px-3 mb-3'}>
          <button
            data-tv-title="Trocar perfil"
            onClick={lockToProfileGate}
            className={`tv-card w-full flex items-center rounded-xl cursor-pointer focus:outline-none text-[#8E8E99] hover:text-white ${
              rail ? 'h-14 px-3 gap-4' : 'h-12 px-3 gap-3'
            }`}
          >
            <Avatar avatar={activeProfile.avatar} name={activeProfile.name} className="w-9 h-9 rounded-lg shrink-0" textClassName="text-base" />
            <span className={`${label} text-left leading-tight`}>
              <span className={`block text-white font-semibold ${rail ? 'text-[17px]' : 'text-sm'}`}>{activeProfile.name}</span>
              <span className="block text-xs">Trocar perfil</span>
            </span>
          </button>
        </div>
      )}

      <nav className={`flex-1 overflow-y-auto scrollbar-none space-y-1 ${rail ? 'px-3' : 'px-3'}`}>
        {NAV.map((n) => {
          const Icon = n.icon;
          return item(n.id, n.label, <Icon className="w-6 h-6 shrink-0" strokeWidth={activeTab === n.id ? 2.4 : 1.8} />, activeTab === n.id);
        })}
      </nav>

      <div className={`px-3 ${rail ? 'pb-8' : 'pb-6'}`}>
        {item(
          'more',
          'Mais',
          <LayoutGrid className="w-6 h-6 shrink-0" strokeWidth={SECONDARY.includes(activeTab) ? 2.4 : 1.8} />,
          SECONDARY.includes(activeTab)
        )}
      </div>
    </aside>
  );

  return rail ? <div className="relative w-[84px] h-screen shrink-0">{aside}</div> : aside;
};
