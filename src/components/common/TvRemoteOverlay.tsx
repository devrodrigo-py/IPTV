import React, { useEffect, useState } from 'react';
import {
  ChevronUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Circle,
  CornerUpLeft,
  Tv,
  X,
  Volume2,
  VolumeX,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

export const TvRemoteOverlay: React.FC = () => {
  const { tvMode, toggleTvMode } = useApp();
  const [isMinimized, setIsMinimized] = useState(false);

  useEffect(() => {
    if (!tvMode) return;

    // Enable keyboard D-pad navigation
    const handleTvKey = (e: KeyboardEvent) => {
      // Find all focusable elements
      const focusable = Array.from(
        document.querySelectorAll<HTMLElement>(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"]), .tv-card'
        )
      ).filter((el) => el.offsetParent !== null && !el.hasAttribute('disabled'));

      const active = document.activeElement as HTMLElement;
      let currentIndex = focusable.indexOf(active);

      if (e.key === 'ArrowDown') {
        e.preventDefault();
        const next = focusable[(currentIndex + 1) % focusable.length];
        next?.focus();
        next?.classList.add('tv-focused');
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        const prev = focusable[(currentIndex - 1 + focusable.length) % focusable.length];
        prev?.focus();
        prev?.classList.add('tv-focused');
      }
    };

    window.addEventListener('keydown', handleTvKey);
    return () => window.removeEventListener('keydown', handleTvKey);
  }, [tvMode]);

  if (!tvMode) return null;

  const simulateKey = (key: string) => {
    window.dispatchEvent(new KeyboardEvent('keydown', { key }));
  };

  if (isMinimized) {
    return (
      <button
        onClick={() => setIsMinimized(false)}
        className="fixed bottom-20 right-6 z-40 p-3 rounded-full bg-[#6B4FE0] text-white shadow-2xl hover:scale-105 transition-all flex items-center gap-2 cursor-pointer border border-white/20"
      >
        <Tv className="w-5 h-5" />
        <span className="text-xs font-bold">Controle TV</span>
      </button>
    );
  }

  return (
    <div className="fixed bottom-20 right-6 z-40 bg-[#16162A]/95 backdrop-blur-2xl border border-[#6B4FE0]/50 rounded-3xl p-4 shadow-2xl w-60 select-none animate-in slide-in-from-bottom duration-200">
      <div className="flex items-center justify-between pb-3 border-b border-[#2A2A45]">
        <div className="flex items-center gap-2">
          <Tv className="w-4 h-4 text-[#1FCFAE]" />
          <h4 className="text-xs font-bold text-white uppercase tracking-wider">
            Controle Remoto TV
          </h4>
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={() => setIsMinimized(true)}
            className="w-6 h-6 rounded-md hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white flex items-center justify-center text-xs cursor-pointer"
            title="Minimizar"
          >
            _
          </button>
          <button
            onClick={toggleTvMode}
            className="w-6 h-6 rounded-md hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
            title="Desativar Modo TV"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* D-Pad Buttons */}
      <div className="py-4 flex flex-col items-center">
        {/* Up */}
        <button
          onClick={() => simulateKey('ArrowUp')}
          className="w-12 h-10 rounded-t-2xl bg-[#1E1E38] hover:bg-[#6B4FE0] text-white flex items-center justify-center transition-all cursor-pointer border border-[#2A2A45]"
        >
          <ChevronUp className="w-5 h-5" />
        </button>

        {/* Left - OK - Right */}
        <div className="flex items-center gap-1 my-1">
          <button
            onClick={() => simulateKey('ArrowLeft')}
            className="w-10 h-12 rounded-l-2xl bg-[#1E1E38] hover:bg-[#6B4FE0] text-white flex items-center justify-center transition-all cursor-pointer border border-[#2A2A45]"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>

          <button
            onClick={() => simulateKey('Enter')}
            className="w-12 h-12 rounded-full bg-gradient-to-tr from-[#6B4FE0] to-[#2A1D6B] hover:scale-105 text-white flex items-center justify-center font-bold text-xs shadow-lg shadow-[#6B4FE0]/40 transition-all cursor-pointer border border-white/20"
          >
            OK
          </button>

          <button
            onClick={() => simulateKey('ArrowRight')}
            className="w-10 h-12 rounded-r-2xl bg-[#1E1E38] hover:bg-[#6B4FE0] text-white flex items-center justify-center transition-all cursor-pointer border border-[#2A2A45]"
          >
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>

        {/* Down */}
        <button
          onClick={() => simulateKey('ArrowDown')}
          className="w-12 h-10 rounded-b-2xl bg-[#1E1E38] hover:bg-[#6B4FE0] text-white flex items-center justify-center transition-all cursor-pointer border border-[#2A2A45]"
        >
          <ChevronDown className="w-5 h-5" />
        </button>
      </div>

      {/* Quick Action Buttons */}
      <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#2A2A45]">
        <button
          onClick={() => simulateKey('Escape')}
          className="py-2 px-3 rounded-xl bg-[#1E1E38] hover:bg-[#2A2A45] text-xs font-semibold text-[#A8A6C0] hover:text-white flex items-center justify-center gap-1.5 cursor-pointer"
        >
          <CornerUpLeft className="w-3.5 h-3.5" /> Voltar
        </button>
        <button
          onClick={() => simulateKey(' ')}
          className="py-2 px-3 rounded-xl bg-[#1E1E38] hover:bg-[#2A2A45] text-xs font-semibold text-[#A8A6C0] hover:text-white flex items-center justify-center gap-1.5 cursor-pointer"
        >
          <Circle className="w-3.5 h-3.5 fill-current text-[#1FCFAE]" /> Play/Pausa
        </button>
      </div>
    </div>
  );
};
