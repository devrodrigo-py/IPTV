import React from 'react';
import {
  Play,
  Tv,
  Film,
  Sparkles,
  Heart,
  History,
  TrendingUp,
  Clock,
  Radio,
  ChevronRight,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { VodItem } from '../types';

export const HomeView: React.FC = () => {
  const {
    filteredChannels,
    history,
    vodItems,
    seriesItems,
    playChannel,
    playVod,
    setActiveTab,
    setIsWrappedOpen,
    setSelectedVodModal,
  } = useApp();

  const heroChannel = filteredChannels[0];
  const featuredVod = vodItems[0];
  const topChannels = filteredChannels.slice(0, 8);

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 select-none">
      {/* Hero Showcase Banner */}
      {heroChannel && (
        <div className="relative rounded-3xl overflow-hidden bg-gradient-to-r from-[#16162A] via-[#1E1E38] to-[#2A1D6B] border border-[#6B4FE0]/40 shadow-2xl p-6 md:p-10 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="relative z-10 max-w-xl">
            <div className="flex items-center gap-2 mb-3">
              <span className="px-2.5 py-1 rounded-lg bg-[#1FCFAE]/20 text-[#1FCFAE] font-bold text-xs uppercase tracking-wider border border-[#1FCFAE]/30 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-[#1FCFAE] animate-ping" />
                Destaque Ao Vivo
              </span>
              <span className="text-xs text-[#A8A6C0] font-medium">Sinal Oficial</span>
            </div>

            <h1 className="text-2xl md:text-4xl font-extrabold text-white tracking-tight font-['Outfit']">
              {heroChannel.name}
            </h1>
            <p className="text-xs md:text-sm text-[#A8A6C0] mt-2 leading-relaxed">
              Assista à transmissão ao vivo com alta resolução, latência otimizada e guia de programação em tempo real no Nebula IPTV.
            </p>

            <div className="flex items-center gap-3 mt-6">
              <button
                onClick={() => playChannel(heroChannel)}
                className="px-6 py-3 rounded-2xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs md:text-sm flex items-center gap-2.5 shadow-xl shadow-[#6B4FE0]/40 transition-transform active:scale-95 cursor-pointer"
              >
                <Play className="w-4 h-4 fill-current" />
                Assistir Ao Vivo
              </button>

              <button
                onClick={() => setActiveTab('channels')}
                className="px-5 py-3 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-xs md:text-sm flex items-center gap-2 backdrop-blur-sm cursor-pointer transition-colors"
              >
                Ver Grade Completa
                <ChevronRight className="w-4 h-4 text-[#A8A6C0]" />
              </button>
            </div>
          </div>

          <div className="relative w-full md:w-80 h-44 md:h-52 rounded-2xl bg-black/40 border border-white/10 flex items-center justify-center p-4 overflow-hidden group">
            {heroChannel.logoUrl ? (
              <img
                src={heroChannel.logoUrl}
                alt={heroChannel.name}
                className="max-h-24 max-w-full object-contain filter drop-shadow group-hover:scale-105 transition-transform duration-300"
              />
            ) : (
              <Tv className="w-16 h-16 text-[#6B4FE0]" />
            )}
            <div className="absolute bottom-3 right-3 px-2 py-0.5 rounded bg-black/70 text-[10px] font-bold text-[#1FCFAE]">
              {heroChannel.resolution || 'HD'}
            </div>
          </div>
        </div>
      )}

      {/* Continue Watching / History */}
      {history.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <History className="w-4 h-4 text-[#6B4FE0]" />
              <h2 className="text-base font-bold text-white tracking-wide">Continuar Assistindo</h2>
            </div>
            <button
              onClick={() => setActiveTab('history')}
              className="text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-medium flex items-center gap-1 cursor-pointer"
            >
              Ver Histórico <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {history.slice(0, 4).map((item) => (
              <div
                key={item.id}
                onClick={() => {
                  const ch = filteredChannels.find((c) => c.id === item.contentId);
                  if (ch) playChannel(ch);
                  else if (item.contentType === 'vod') {
                    const vod = vodItems.find((v) => v.id === item.contentId);
                    if (vod) playVod(vod);
                  }
                }}
                className="p-3.5 rounded-2xl bg-[#16162A] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] flex items-center gap-3 cursor-pointer transition-all shadow-sm group"
              >
                <div className="w-12 h-12 rounded-xl bg-black/40 overflow-hidden relative shrink-0 flex items-center justify-center border border-white/5">
                  {item.posterUrl ? (
                    <img
                      src={item.posterUrl}
                      alt={item.title}
                      className="w-full h-full object-contain p-1"
                    />
                  ) : (
                    <Tv className="w-5 h-5 text-[#6B4FE0]" />
                  )}
                  <div className="absolute inset-0 bg-[#6B4FE0]/60 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                    <Play className="w-4 h-4 text-white fill-current" />
                  </div>
                </div>

                <div className="min-w-0 flex-1">
                  <h4 className="font-bold text-xs text-white truncate group-hover:text-[#1FCFAE]">
                    {item.title}
                  </h4>
                  <p className="text-[11px] text-[#A8A6C0] truncate mt-0.5">
                    {item.subtitle || 'Última reprodução'}
                  </p>
                  <span className="text-[10px] text-[#A8A6C0]/70 font-mono mt-0.5 block">
                    {new Date(item.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Top Channels Grid */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Radio className="w-4 h-4 text-[#1FCFAE]" />
            <h2 className="text-base font-bold text-white tracking-wide">Canais em Destaque</h2>
          </div>
          <button
            onClick={() => setActiveTab('channels')}
            className="text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-medium flex items-center gap-1 cursor-pointer"
          >
            Ver Todos ({filteredChannels.length}) <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {topChannels.map((ch, idx) => (
            <ChannelCard key={ch.id} channel={ch} index={idx} />
          ))}
        </div>
      </section>

      {/* Popular Movies (VOD) Row */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Film className="w-4 h-4 text-[#FF6F91]" />
            <h2 className="text-base font-bold text-white tracking-wide">Filmes em Alta (VOD)</h2>
          </div>
          <button
            onClick={() => setActiveTab('vod')}
            className="text-xs text-[#A8A6C0] hover:text-[#FF6F91] font-medium flex items-center gap-1 cursor-pointer"
          >
            Explorar Filmes <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
          {vodItems.slice(0, 5).map((vod) => (
            <div
              key={vod.id}
              onClick={() => setSelectedVodModal(vod)}
              className="group bg-[#16162A] rounded-2xl border border-[#2A2A45] hover:border-[#6B4FE0] overflow-hidden cursor-pointer transition-all duration-200"
            >
              <div className="relative aspect-[2/3] w-full bg-black/40 overflow-hidden">
                <img
                  src={vod.posterUrl}
                  alt={vod.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                />
                <div className="absolute top-2 right-2 px-1.5 py-0.5 rounded bg-black/70 text-[10px] font-bold text-[#FF6F91]">
                  ★ {vod.rating}
                </div>
              </div>
              <div className="p-2.5">
                <h4 className="font-bold text-xs text-white truncate group-hover:text-[#1FCFAE]">
                  {vod.title}
                </h4>
                <p className="text-[10px] text-[#A8A6C0] mt-0.5">{vod.category}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};
