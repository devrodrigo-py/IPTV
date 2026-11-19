import React from 'react';
import { ListVideo, Heart, History, LayoutGrid, BarChart3, Sparkles, Settings, Users, type LucideIcon } from 'lucide-react';
import { useApp, TabType } from '../context/AppContext';

interface Tile {
  id: TabType | 'wrapped' | 'profiles';
  title: string;
  desc: string;
  icon: LucideIcon;
}

const TILES: Tile[] = [
  { id: 'playlists', title: 'Minhas listas', desc: 'Adicionar e atualizar M3U e Xtream', icon: ListVideo },
  { id: 'favorites', title: 'Canais favoritos', desc: 'Seus canais marcados', icon: Heart },
  { id: 'history', title: 'Histórico', desc: 'O que você assistiu', icon: History },
  { id: 'multiview', title: 'Multitela', desc: 'Vários canais ao mesmo tempo', icon: LayoutGrid },
  { id: 'stats', title: 'Estatísticas', desc: 'Tempo assistido e preferências', icon: BarChart3 },
  { id: 'wrapped', title: 'Sua retrospectiva', desc: 'Seu ano no Nebula', icon: Sparkles },
  { id: 'profiles', title: 'Perfis', desc: 'Trocar ou gerenciar perfis', icon: Users },
  { id: 'settings', title: 'Configurações', desc: 'Player, aparelho, controle parental', icon: Settings },
];

/** Secondary destinations, kept out of the main menu so it stays short. */
export const MoreView: React.FC = () => {
  const { setActiveTab, setIsWrappedOpen, lockToProfileGate } = useApp();

  const open = (t: Tile) => {
    if (t.id === 'wrapped') setIsWrappedOpen(true);
    else if (t.id === 'profiles') lockToProfileGate();
    else setActiveTab(t.id);
  };

  return (
    <div className="px-8 md:px-14 py-12 max-w-[1600px] mx-auto">
      <h1 className="font-display text-4xl font-bold text-white tracking-tight mb-2">Mais</h1>
      <p className="text-[#A1A1AA] text-base mb-10">Listas, preferências e tudo o que não está no menu principal.</p>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
        {TILES.map((t, i) => {
          const Icon = t.icon;
          return (
            <div
              key={t.id}
              role="button"
              tabIndex={0}
              data-autofocus={i === 0 ? true : undefined}
              data-tv-title={t.title}
              onClick={() => open(t)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  open(t);
                }
              }}
              className="tv-card group rounded-2xl bg-[#141418] hover:bg-[#1C1C22] p-6 cursor-pointer focus:outline-none min-h-[150px] flex flex-col justify-between"
            >
              <Icon className="w-8 h-8 text-white/80 group-hover:text-white" strokeWidth={1.6} />
              <div>
                <h2 className="text-white text-lg font-semibold">{t.title}</h2>
                <p className="text-sm text-[#8E8E99] mt-1">{t.desc}</p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
