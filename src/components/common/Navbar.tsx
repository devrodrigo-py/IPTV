import React, { useState } from 'react';
import {
  Search,
  Tv,
  Sparkles,
  User,
  Shield,
  Layers,
  LogOut,
  Maximize2,
  Lock,
  X,
} from 'lucide-react';
import { Avatar } from '../profiles/Avatar';
import { useApp } from '../../context/AppContext';

export const Navbar: React.FC = () => {
  const {
    activeTab,
    activeProfile,
    lockToProfileGate,
    searchQuery,
    setSearchQuery,
    setActiveTab,
    setIsWrappedOpen,
    tvMode,
    toggleTvMode,
  } = useApp();

  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [previousTab, setPreviousTab] = useState<string>('home');

  return (
    <header className="h-16 border-b border-[#2A2A31]/50 bg-[#060608]/80 backdrop-blur-xl px-6 flex items-center justify-between sticky top-0 z-30">
      {/* Search Bar */}
      <div className="flex-1 max-w-md relative">
        <div className="relative flex items-center">
          <Search className="w-4 h-4 text-[#A1A1AA] absolute left-3 pointer-events-none" />
          <input
            type="text"
            placeholder="Buscar canais, filmes, séries e programas..."
            value={searchQuery}
            onChange={(e) => {
              const val = e.target.value;
              setSearchQuery(val);
              if (val.trim().length > 0) {
                setActiveTab('search');
              } else {
                setActiveTab(previousTab as any);
              }
            }}
            onFocus={() => {
              if (activeTab !== 'search') {
                setPreviousTab(activeTab);
              }
              if (searchQuery.trim().length > 0) {
                setActiveTab('search');
              }
            }}
            className="w-full bg-[#141418] hover:bg-[#1E1E24] focus:bg-[#1E1E24] text-sm text-[#F5F5F7] placeholder-[#A1A1AA]/60 pl-10 pr-9 py-2 rounded-xl border border-[#2A2A31] focus:border-[#7C5CFF] outline-none transition-all shadow-inner"
          />
          {searchQuery && (
            <button
              onClick={() => {
                setSearchQuery('');
                setActiveTab(previousTab as any);
              }}
              className="absolute right-3 text-[#A1A1AA] hover:text-white cursor-pointer"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3">


        {/* Profile Avatar / Switcher */}
        <div className="relative">
          <button
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            className="flex items-center gap-2.5 p-1.5 rounded-xl hover:bg-[#141418] border border-transparent hover:border-[#2A2A31] transition-all cursor-pointer"
          >
            <div className="relative">
              <Avatar avatar={activeProfile?.avatar} name={activeProfile?.name || 'U'} className="w-8 h-8 rounded-lg" textClassName="text-xs" />
              {activeProfile?.isKids && (
                <span className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-[#FF6F91] rounded-full border-2 border-[#060608] flex items-center justify-center text-[8px] font-bold">
                  K
                </span>
              )}
            </div>
            <span className="hidden md:block text-xs font-semibold text-[#F5F5F7]">
              {activeProfile?.name || 'Perfil'}
            </span>
          </button>

          {showProfileMenu && (
            <div className="absolute right-0 mt-2 w-56 rounded-2xl bg-[#141418] border border-[#2A2A31] shadow-2xl p-2 z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="px-3 py-2 border-b border-[#2A2A31]">
                <p className="text-xs font-bold text-white truncate">{activeProfile?.name}</p>
                <p className="text-[11px] text-[#A1A1AA]">
                  {activeProfile?.isKids ? 'Espaço Kids (Restrito)' : 'Perfil Padrão'}
                </p>
              </div>

              <div className="py-1">
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    lockToProfileGate();
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs text-[#A1A1AA] hover:text-white hover:bg-[#2A2A31] transition-colors text-left"
                >
                  <Lock className="w-4 h-4 text-[#7C5CFF]" />
                  Trocar de Perfil
                </button>
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    setActiveTab('settings');
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs text-[#A1A1AA] hover:text-white hover:bg-[#2A2A31] transition-colors text-left"
                >
                  <Shield className="w-4 h-4 text-[#22D3A6]" />
                  Controle Parental & Ajustes
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
