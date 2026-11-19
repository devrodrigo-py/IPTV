import React, { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { Search, Mic } from 'lucide-react';
import { isVoiceSearchAvailable, voiceSearch } from '../platform/nativePlayer';
import { useApp } from '../context/AppContext';
import { PosterCard } from '../components/media/PosterCard';
import { ChannelTile } from '../components/channels/ChannelTile';

const RESULT_LIMIT = 42;
type Filter = 'all' | 'channels' | 'vod' | 'series';

/** Search across channels, movies and series; voice input where the TV offers it. */
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
    getProgressFraction,
    enrichArtwork,
  } = useApp();

  const [filter, setFilter] = useState<Filter>('all');
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
  const results = useMemo(() => {
    if (!q) return { channels: [], vod: [], series: [] };
    return {
      channels: filteredChannels.filter((c) => c.name.toLowerCase().includes(q) || (c.groupTitle || '').toLowerCase().includes(q)),
      vod: vodItems.filter((v) => v.title.toLowerCase().includes(q) || v.category.toLowerCase().includes(q)),
      series: seriesItems.filter((s) => s.title.toLowerCase().includes(q) || s.category.toLowerCase().includes(q)),
    };
  }, [q, filteredChannels, vodItems, seriesItems]);
  const total = results.channels.length + results.vod.length + results.series.length;

  const pills: { id: Filter; label: string; n: number }[] = [
    { id: 'all', label: 'Tudo', n: total },
    { id: 'vod', label: 'Filmes', n: results.vod.length },
    { id: 'series', label: 'Séries', n: results.series.length },
    { id: 'channels', label: 'Canais', n: results.channels.length },
  ];
  const show = (f: Filter) => filter === 'all' || filter === f;

  return (
    <div className="px-14 pt-10 pb-12 space-y-8 select-none">
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-3xl">
          <Search className="w-7 h-7 text-white/40 absolute left-5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Filmes, séries, canais…"
            // On TV the on-screen keyboard would cover the screen as soon as the page opens.
            autoFocus={!tvMode}
            className="w-full h-16 bg-white/[0.06] focus:bg-white/10 rounded-lg pl-16 pr-5 text-2xl font-display font-semibold text-white placeholder-white/30 outline-none"
          />
        </div>
        {voiceAvailable && (
          <button
            data-autofocus
            onClick={startVoice}
            data-tv-title="Buscar por voz"
            className="tv-card h-16 px-6 rounded-lg bg-white text-black text-lg font-bold flex items-center gap-3 cursor-pointer focus:outline-none"
          >
            <Mic className="w-6 h-6" /> {listening ? 'Ouvindo…' : 'Falar'}
          </button>
        )}
      </div>

      {!q ? (
        <p className="text-white/40 text-lg">Digite ou fale o nome de um filme, série ou canal.</p>
      ) : total === 0 ? (
        <p className="text-white/50 text-lg">Nada encontrado para “{searchQuery}”.</p>
      ) : (
        <>
          <div className="flex items-center gap-2">
            {pills.map((p) => (
              <button
                key={p.id}
                onClick={() => setFilter(p.id)}
                data-tv-title={`Filtro: ${p.label}`}
                className={`tv-card h-10 px-5 rounded-full text-[15px] font-semibold cursor-pointer focus:outline-none ${
                  filter === p.id ? 'bg-white text-black' : 'bg-white/10 text-white/75 hover:bg-white/20'
                }`}
              >
                {p.label} <span className="opacity-50 ml-1">{p.n}</span>
              </button>
            ))}
          </div>

          {show('vod') && results.vod.length > 0 && (
            <section className="space-y-4">
              <h2 className="font-display text-[22px] font-semibold text-white">Filmes</h2>
              <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-x-4 gap-y-6">
                {results.vod.slice(0, RESULT_LIMIT).map((v) => (
                  <PosterCard key={v.id} title={v.title} subtitle={v.category} imageUrl={v.posterUrl} progress={getProgressFraction(v.id)} onSelect={() => setSelectedVodModal(v)} onVisible={() => enrichArtwork('vod', v.id)} />
                ))}
              </div>
            </section>
          )}

          {show('series') && results.series.length > 0 && (
            <section className="space-y-4">
              <h2 className="font-display text-[22px] font-semibold text-white">Séries</h2>
              <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-x-4 gap-y-6">
                {results.series.slice(0, RESULT_LIMIT).map((s) => (
                  <PosterCard key={s.id} title={s.title} subtitle={s.category} imageUrl={s.posterUrl} onSelect={() => setSelectedSeriesModal(s)} onVisible={() => enrichArtwork('series', s.id)} />
                ))}
              </div>
            </section>
          )}

          {show('channels') && results.channels.length > 0 && (
            <section className="space-y-4">
              <h2 className="font-display text-[22px] font-semibold text-white">Canais</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {results.channels.slice(0, RESULT_LIMIT).map((c) => (
                  <ChannelTile key={c.id} channel={c} />
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </div>
  );
};
