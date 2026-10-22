import React, { useState } from 'react';
import {
  X,
  Sparkles,
  Trophy,
  Clock,
  Tv,
  Heart,
  Share2,
  ChevronRight,
  ChevronLeft,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

interface NebulaWrappedModalProps {
  onClose: () => void;
}

export const NebulaWrappedModal: React.FC<NebulaWrappedModalProps> = ({ onClose }) => {
  const { stats, activeProfile } = useApp();
  const [currentSlide, setCurrentSlide] = useState(0);

  const hoursWatched = (stats.totalMinutesWatched / 60).toFixed(1);
  const sortedChannels = Object.entries(stats.channelPlayCounts).sort((a, b) => b[1] - a[1]);
  const topChannel = sortedChannels[0] || ['NASA TV HD', 42];

  const sortedGenres = Object.entries(stats.genreCounts).sort((a, b) => b[1] - a[1]);
  const topGenre = sortedGenres[0] || ['Documentários', 45];

  const slides = [
    // Slide 0: Intro
    {
      badge: 'Retrospectiva Cósmica',
      title: `Nebula Wrapped 2026`,
      subtitle: `Olá, ${activeProfile?.name || 'Explorador'}! Pronto para decolar e relembrar sua jornada de entretenimento neste ano?`,
      gradient: 'from-[#6B4FE0] via-[#2A1D6B] to-[#07070F]',
      icon: Sparkles,
      iconColor: '#FF6F91',
    },
    // Slide 1: Watch time
    {
      badge: 'Tempo em Órbita',
      title: `${hoursWatched} Horas Conectadas`,
      subtitle: `Você explorou transmissões do mundo todo em ${stats.daysActive} dias ativos no Nebula IPTV.`,
      stat: `${stats.totalMinutesWatched.toLocaleString()} Minutos`,
      statLabel: 'Tempo Total de Reprodução',
      gradient: 'from-[#1FCFAE]/40 via-[#16162A] to-[#07070F]',
      icon: Clock,
      iconColor: '#1FCFAE',
    },
    // Slide 2: Top Channel
    {
      badge: 'Canal Mais Sintonizado',
      title: topChannel[0],
      subtitle: `Você deu o play ${topChannel[1]} vezes nesta transmissão! Este foi o seu refúgio preferido em frente à tela.`,
      stat: `#1 Mais Assistido`,
      statLabel: `${topChannel[1]} sessões de stream`,
      gradient: 'from-[#6B4FE0]/50 via-[#1E1E38] to-[#07070F]',
      icon: Trophy,
      iconColor: '#FFB800',
    },
    // Slide 3: Top Genre & Personality
    {
      badge: 'Sua Personalidade de Espectador',
      title: 'O Explorador Cósmico',
      subtitle: `Seu gênero mais assistido foi "${topGenre[0]}". Você tem uma curiosidade sem limites pelas fronteiras do conhecimento e entretenimento.`,
      stat: topGenre[0],
      statLabel: 'Gênero Predominante',
      gradient: 'from-[#FF6F91]/40 via-[#2A1D6B] to-[#07070F]',
      icon: Heart,
      iconColor: '#FF6F91',
    },
  ];

  const active = slides[currentSlide];
  const Icon = active.icon;

  return (
    <div className="fixed inset-0 z-50 bg-black/90 backdrop-blur-xl flex items-center justify-center p-4">
      <div className="w-full max-w-lg rounded-3xl bg-[#07070F] border border-[#6B4FE0]/50 overflow-hidden shadow-2xl relative flex flex-col min-h-[500px]">
        {/* Top Header */}
        <div className="absolute top-4 left-4 right-4 z-20 flex items-center justify-between">
          {/* Slide Progress bars */}
          <div className="flex-1 flex gap-1.5 mr-4">
            {slides.map((_, idx) => (
              <div
                key={idx}
                className="h-1 flex-1 rounded-full bg-white/20 overflow-hidden"
              >
                <div
                  className={`h-full bg-white transition-all duration-300 ${
                    idx <= currentSlide ? 'w-full' : 'w-0'
                  }`}
                />
              </div>
            ))}
          </div>

          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center cursor-pointer transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Slide Content with Dynamic Background */}
        <div
          className={`flex-1 p-8 pt-16 flex flex-col justify-between bg-gradient-to-b ${active.gradient} transition-all duration-500`}
        >
          <div className="space-y-4">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/10 text-xs font-bold text-white uppercase tracking-wider backdrop-blur-md">
              <Icon className="w-3.5 h-3.5" style={{ color: active.iconColor }} />
              {active.badge}
            </span>

            <h2 className="text-3xl md:text-4xl font-black text-white tracking-tight font-['Outfit']">
              {active.title}
            </h2>

            <p className="text-sm md:text-base text-[#F5F3FF]/80 leading-relaxed font-normal">
              {active.subtitle}
            </p>

            {active.stat && (
              <div className="pt-6">
                <div className="p-4 rounded-2xl bg-black/40 border border-white/10 backdrop-blur-md">
                  <span className="text-2xl md:text-3xl font-extrabold text-[#1FCFAE] font-mono block">
                    {active.stat}
                  </span>
                  <span className="text-xs text-[#A8A6C0] font-medium block mt-1">
                    {active.statLabel}
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Navigation Footer */}
          <div className="flex items-center justify-between pt-6 border-t border-white/10 mt-6">
            <button
              onClick={() => setCurrentSlide((prev) => Math.max(0, prev - 1))}
              disabled={currentSlide === 0}
              className="p-2 rounded-xl bg-white/10 hover:bg-white/20 disabled:opacity-30 text-white cursor-pointer"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>

            <span className="text-xs font-mono text-white/60">
              {currentSlide + 1} / {slides.length}
            </span>

            {currentSlide < slides.length - 1 ? (
              <button
                onClick={() => setCurrentSlide((prev) => Math.min(slides.length - 1, prev + 1))}
                className="px-5 py-2.5 rounded-xl bg-white text-black font-bold text-xs flex items-center gap-1 cursor-pointer hover:bg-white/90"
              >
                Próximo <ChevronRight className="w-4 h-4" />
              </button>
            ) : (
              <button
                onClick={onClose}
                className="px-5 py-2.5 rounded-xl bg-[#6B4FE0] text-white font-bold text-xs flex items-center gap-1 cursor-pointer hover:bg-[#6B4FE0]/80"
              >
                Concluir Wrapped
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
