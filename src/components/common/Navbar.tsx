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
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

export const Navbar: React.FC = () => {
  const {
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

  return (
    <header className="h-16 border-b border-[#2A2A45]/50 bg-[#07070F]/80 backdrop-blur-xl px-6 flex items-center justify-between sticky top-0 z-30">
      {/* Search Bar */}
      <div className="flex-1 max-w-md relative">
        <div className="relative flex items-center">
          <Search className="w-4 h-4 text-[#A8A6C0] absolute left-3 pointer-events-none" />
          <input
            type="text"
            placeholder="Buscar canais, filmes, séries e programas..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              if (e.target.value.trim().length > 0) {
                setActiveTab('search');
              }
            }}
            onFocus={() => {
              if (searchQuery.trim().length > 0) {
                setActiveTab('search');
              }
            }}
            className="w-full bg-[#16162A] hover:bg-[#1E1E38] focus:bg-[#1E1E38] text-sm text-[#F5F3FF] placeholder-[#A8A6C0]/60 pl-10 pr-4 py-2 rounded-xl border border-[#2A2A45] focus:border-[#6B4FE0] outline-none transition-all shadow-inner"
          />
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3">
        {/* Nebula Wrapped Button */}
        <button
          onClick={() => setIsWrappedOpen(true)}
          className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-gradient-to-r from-[#6B4FE0]/30 to-[#FF6F91]/30 hover:from-[#6B4FE0]/50 hover:to-[#FF6F91]/50 border border-[#FF6F91]/40 text-[#F5F3FF] text-xs font-semibold shadow-sm transition-all cursor-pointer group"
        >
          <Sparkles className="w-4 h-4 text-[#FF6F91] group-hover:rotate-12 transition-transform" />
          <span>Nebula Wrapped</span>
        </button>

        {/* TV Mode Toggle (10-foot Couch UI) */}
        <button
          onClick={toggleTvMode}
          className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
            tvMode
              ? 'bg-[#6B4FE0] text-white border-[#6B4FE0] shadow-lg shadow-[#6B4FE0]/40'
              : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border-[#2A2A45]'
          }`}
          title="Modo TV / Navegação por Controle"
        >
          <Tv className="w-4 h-4" />
          <span className="hidden md:inline">{tvMode ? 'Modo TV: Ativo' : 'Modo TV'}</span>
        </button>

        {/* Profile Avatar / Switcher */}
        <div className="relative">
          <button
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            className="flex items-center gap-2.5 p-1.5 rounded-xl hover:bg-[#16162A] border border-transparent hover:border-[#2A2A45] transition-all cursor-pointer"
          >
            <div className="relative">
              <img
                src={activeProfile?.avatar}
                alt={activeProfile?.name}
                className="w-8 h-8 rounded-lg object-cover border border-[#6B4FE0]/50"
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
              {activeProfile?.isKids && (
                <span className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-[#FF6F91] rounded-full border-2 border-[#07070F] flex items-center justify-center text-[8px] font-bold">
                  K
                </span>
              )}
            </div>
            <span className="hidden md:block text-xs font-semibold text-[#F5F3FF]">
              {activeProfile?.name || 'Perfil'}
            </span>
          </button>

          {showProfileMenu && (
            <div className="absolute right-0 mt-2 w-56 rounded-2xl bg-[#16162A] border border-[#2A2A45] shadow-2xl p-2 z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="px-3 py-2 border-b border-[#2A2A45]">
                <p className="text-xs font-bold text-white truncate">{activeProfile?.name}</p>
                <p className="text-[11px] text-[#A8A6C0]">
                  {activeProfile?.isKids ? 'Espaço Kids (Restrito)' : 'Perfil Padrão'}
                </p>
              </div>

              <div className="py-1">
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    lockToProfileGate();
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs text-[#A8A6C0] hover:text-white hover:bg-[#2A2A45] transition-colors text-left"
                >
                  <Lock className="w-4 h-4 text-[#6B4FE0]" />
                  Trocar de Perfil
                </button>
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    setActiveTab('settings');
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs text-[#A8A6C0] hover:text-white hover:bg-[#2A2A45] transition-colors text-left"
                >
                  <Shield className="w-4 h-4 text-[#1FCFAE]" />
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
