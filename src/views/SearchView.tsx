import React, { useDeferredValue, useEffect, useState } from 'react';
import { Search, Tv, Film, Play, Star, Mic } from 'lucide-react';
import { isVoiceSearchAvailable, voiceSearch } from '../platform/nativePlayer';
import { useApp } from '../context/AppContext';
import { ChannelCard } from '../components/channels/ChannelCard';
import { VodItem, SeriesItem } from '../types';

const RESULT_LIMIT = 60;

export const SearchView: React.FC = () => {
  const {
    searchQuery,
    setSearchQuery,
    tvMode,
    filteredChannels,
    vodItems,
    seriesItems,
    setSelectedVodModal,
    setSelectedSeriesModal,
  } = useApp();

  const [activeFilter, setActiveFilter] = useState<'all' | 'channels' | 'vod' | 'series'>('all');
  const [voiceAvailable, setVoiceAvailable] = useState(false);
  const [listening, setListening] = useState(false);
  useEffect(() => {
    void isVoiceSearchAvailable().then(setVoiceAvailable);
  }, []);
  const startVoice = async () => {
    setListening(true);
    try {
      const text = await voiceSearch();
      if (text) setSearchQuery(text);
    } catch {
      setVoiceAvailable(false);
    } finally {
      setListening(false);
    }
  };

  // Typing stays responsive on TV sticks while big lists are filtered.
  const q = useDeferredValue(searchQuery).toLowerCase().trim();

  const matchedChannels = filteredChannels.filter((c) => {
    if (!q) return true;
    return c.name.toLowerCase().includes(q) || (c.groupTitle || '').toLowerCase().includes(q);
  });

  const matchedVod = vodItems.filter((v) => {
    if (!q) return true;
    return (
      v.title.toLowerCase().includes(q) ||
      v.category.toLowerCase().includes(q) ||
      v.description.toLowerCase().includes(q)
    );
  });

  const matchedSeries = seriesItems.filter((s) => {
    if (!q) return true;
    return (
      s.title.toLowerCase().includes(q) ||
      s.category.toLowerCase().includes(q) ||
      s.overview.toLowerCase().includes(q)
    );
  });

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Header and Search input */}
      <div className="space-y-4 pb-4 border-b border-[#2A2A31]">
        <div className="flex items-center gap-2">
          <Search className="w-5 h-5 text-[#7C5CFF]" />
          <h1 className="text-xl font-bold text-white tracking-tight">Busca Global</h1>
        </div>

        <div className="relative max-w-2xl">
          <Search className="w-5 h-5 text-[#A1A1AA] absolute left-4 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Pesquise por nome do canal, filme, série, ator ou categoria..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#141418] text-sm text-white placeholder-[#A1A1AA] pl-12 pr-4 py-3 rounded-2xl border border-[#2A2A31] focus:border-[#7C5CFF] outline-none shadow-inner"
            // On TV the on-screen keyboard would cover the screen as soon as the page opens.
            autoFocus={!tvMode}
          />
        </div>
        {voiceAvailable && (
          <button
            data-autofocus
            onClick={startVoice}
            data-tv-title="Buscar por voz"
            className="tv-card w-fit px-5 py-3 rounded-2xl bg-[#7C5CFF] text-white text-sm font-bold flex items-center gap-2 cursor-pointer focus:outline-none"
          >
            <Mic className="w-5 h-5" /> {listening ? 'Ouvindo…' : 'Buscar por voz'}
          </button>
        )}

        {/* Filter Pills */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveFilter('all')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'all'
                ? 'bg-[#7C5CFF] text-white'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border border-[#2A2A31]'
            }`}
          >
            Tudo ({matchedChannels.length + matchedVod.length + matchedSeries.length})
          </button>
          <button
            onClick={() => setActiveFilter('channels')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'channels'
                ? 'bg-[#7C5CFF] text-white'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border border-[#2A2A31]'
            }`}
          >
            Canais ({matchedChannels.length})
          </button>
          <button
            onClick={() => setActiveFilter('vod')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'vod'
                ? 'bg-[#7C5CFF] text-white'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border border-[#2A2A31]'
            }`}
          >
            Filmes ({matchedVod.length})
          </button>
          <button
            onClick={() => setActiveFilter('series')}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              activeFilter === 'series'
                ? 'bg-[#7C5CFF] text-white'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border border-[#2A2A31]'
            }`}
          >
            Séries ({matchedSeries.length})
          </button>
        </div>
      </div>

      {/* Results */}
      {(activeFilter === 'all' || activeFilter === 'channels') && matchedChannels.length > 0 && (
        <section className="space-y-3">
          <h2 className="text-sm font-bold text-[#A1A1AA] uppercase tracking-wider">
            Canais Ao Vivo ({matchedChannels.length})
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
            {matchedChannels.slice(0, RESULT_LIMIT).map((ch, idx) => (
              <ChannelCard key={ch.id} channel={ch} index={idx} />
            ))}
          </div>
        </section>
      )}

      {(activeFilter === 'all' || activeFilter === 'vod') && matchedVod.length > 0 && (
        <section className="space-y-3 pt-4">
          <h2 className="text-sm font-bold text-[#A1A1AA] uppercase tracking-wider">
            Filmes (VOD) ({matchedVod.length})
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
            {matchedVod.slice(0, RESULT_LIMIT).map((vod) => (
              <div
                key={vod.id}
                tabIndex={0}
                data-tv-title={`Filme: ${vod.title}`}
                onClick={() => setSelectedVodModal(vod)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') { e.preventDefault(); setSelectedVodModal(vod); }
                }}
                className="tv-card group bg-[#141418] rounded-2xl border border-[#2A2A31] hover:border-[#7C5CFF] overflow-hidden cursor-pointer transition-all focus:outline-none"
              >
                <div className="relative aspect-[2/3] w-full bg-black/40 overflow-hidden">
                  <img
                    src={vod.posterUrl}
                    alt={vod.title}
                    className="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                  <div className="absolute top-2 right-2 px-1.5 py-0.5 rounded bg-black/70 text-[10px] font-bold text-[#FF6F91]">
                    ★ {vod.rating}
                  </div>
                </div>
                <div className="p-2.5">
                  <h4 className="font-bold text-xs text-white truncate">{vod.title}</h4>
                  <p className="text-[10px] text-[#A1A1AA] mt-0.5">{vod.category}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {(activeFilter === 'all' || activeFilter === 'series') && matchedSeries.length > 0 && (
        <section className="space-y-3 pt-4">
          <h2 className="text-sm font-bold text-[#A1A1AA] uppercase tracking-wider">
            Séries ({matchedSeries.length})
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
            {matchedSeries.slice(0, RESULT_LIMIT).map((series) => (
              <div
                key={series.id}
                tabIndex={0}
                data-tv-title={`Série: ${series.title}`}
                onClick={() => setSelectedSeriesModal(series)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') { e.preventDefault(); setSelectedSeriesModal(series); }
                }}
                className="tv-card group bg-[#141418] rounded-2xl border border-[#2A2A31] hover:border-[#7C5CFF] p-3 cursor-pointer transition-all focus:outline-none"
              >
                <h4 className="font-bold text-xs text-white truncate">{series.title}</h4>
                <p className="text-[10px] text-[#A1A1AA] mt-0.5 line-clamp-1">{series.overview}</p>
              </div>
            ))}
          </div>
        </section>
      )}

    </div>
  );
};
