import React, { useEffect, useMemo, useState } from 'react';
import { Upload, X, Play, Tv } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Channel, EpgProgram } from '../types';
import { useProgressiveList } from '../hooks/useProgressiveList';

const SLOT_MIN = 30;
const SLOTS = 6; // 3 hours on screen
const SLOT_PX = 200;
const ROW_H = 76;

function hhmm(t: number | string) {
  const d = new Date(t);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

const ChannelLogo: React.FC<{ channel: Channel }> = ({ channel }) => {
  const [broken, setBroken] = useState(false);
  return (
    <div className="relative w-16 h-10 rounded bg-white/5 shrink-0 overflow-hidden">
      {channel.logoUrl && !broken ? (
        <img src={channel.logoUrl} alt="" loading="lazy" onError={() => setBroken(true)} className="absolute inset-0 w-full h-full object-contain p-1" />
      ) : (
        <Tv className="absolute inset-0 m-auto w-5 h-5 text-white/25" strokeWidth={1.4} />
      )}
    </div>
  );
};

/** Programme grid: time ruler, proportional programme blocks and a "now" line. */
export const EpgView: React.FC = () => {
  const { filteredChannels, getChannelPrograms, playChannel, importXmltv, importEpgFromUrl, playlists, tvMode } = useApp();
  const [now, setNow] = useState(Date.now());
  const [selected, setSelected] = useState<{ program: EpgProgram; channel: Channel } | null>(null);
  const [isImportOpen, setIsImportOpen] = useState(false);
  const [epgUrlInput, setEpgUrlInput] = useState(() => playlists.find((p) => p.epgUrl)?.epgUrl || '');
  const [importing, setImporting] = useState(false);
  const [importStatus, setImportStatus] = useState<string | null>(null);

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 60_000);
    return () => clearInterval(t);
  }, []);

  // Window starts at the last half hour.
  const windowStart = useMemo(() => {
    const d = new Date(now);
    d.setMinutes(d.getMinutes() < 30 ? 0 : 30, 0, 0);
    return d.getTime();
  }, [now]);
  const windowEnd = windowStart + SLOTS * SLOT_MIN * 60_000;
  const pxPerMs = SLOT_PX / (SLOT_MIN * 60_000);
  const timelineW = SLOTS * SLOT_PX;
  const nowX = (now - windowStart) * pxPerMs;

  const numberOf = useMemo(() => new Map(filteredChannels.map((c, i) => [c.id, i + 1])), [filteredChannels]);
  const { visible, hasMore, sentinelRef } = useProgressiveList(filteredChannels, 30);

  const handleUrlImport = async () => {
    if (!epgUrlInput.trim()) return;
    setImporting(true);
    setImportStatus('Baixando e processando o guia…');
    const res = await importEpgFromUrl(epgUrlInput.trim());
    setImporting(false);
    setImportStatus(res.success ? `${res.programCount} programas importados.` : res.message || 'Falha ao importar o guia.');
  };

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = async (ev) => {
      const text = ev.target?.result as string;
      if (!text) return;
      const res = await importXmltv(text);
      setImportStatus(res.success ? `${res.programCount} programas importados.` : 'Nenhum programa válido no arquivo.');
    };
    reader.readAsText(file);
  };

  return (
    <div className="h-full flex flex-col overflow-hidden select-none">
      <header className="shrink-0 flex items-end justify-between px-14 pt-10 pb-6">
        <div>
          <h1 className="font-display text-4xl font-bold text-white tracking-tight">Guia</h1>
          <p className="text-white/50 mt-1">
            {(() => {
              const d = new Date(now).toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' });
              return d.charAt(0).toUpperCase() + d.slice(1);
            })()}{' '}
            · {hhmm(now)}
          </p>
        </div>
        <button
          onClick={() => setIsImportOpen(true)}
          data-tv-skip={tvMode ? true : undefined}
          className="h-11 px-5 rounded-md bg-white/10 hover:bg-white/20 text-white text-sm font-semibold flex items-center gap-2 cursor-pointer"
        >
          <Upload className="w-4 h-4" /> Importar guia
        </button>
      </header>

      {filteredChannels.length === 0 ? (
        <p className="px-14 text-white/50">Adicione uma lista em Mais › Minhas listas para ver a programação.</p>
      ) : (
        <div className="flex-1 min-h-0 overflow-auto scrollbar-none px-14 pb-10">
          <div style={{ width: 288 + timelineW }}>
            {/* Time ruler */}
            <div className="sticky top-0 z-20 flex bg-[#060608] h-14">
              <div className="w-72 shrink-0 sticky left-0 bg-[#060608] z-10" />
              <div className="relative" style={{ width: timelineW }}>
                {Array.from({ length: SLOTS }).map((_, i) => (
                  <span key={i} className="absolute bottom-2 text-sm font-medium text-white/50" style={{ left: i * SLOT_PX + 8 }}>
                    {hhmm(windowStart + i * SLOT_MIN * 60_000)}
                  </span>
                ))}
                {nowX >= 0 && nowX <= timelineW && (
                  <span className="absolute top-0 -translate-x-1/2 px-1.5 py-0.5 rounded bg-[#7C5CFF] text-[11px] font-bold text-white" style={{ left: nowX }}>
                    AGORA
                  </span>
                )}
              </div>
            </div>

            {visible.map((ch) => {
              const progs = getChannelPrograms(ch.id).filter((p) => Date.parse(p.endUtc) > windowStart && Date.parse(p.startUtc) < windowEnd);
              return (
                <div key={ch.id} className="flex border-b border-white/5" style={{ height: ROW_H }}>
                  <div
                    tabIndex={0}
                    role="button"
                    data-nozoom
                    data-tv-title={`Assistir ${ch.name}`}
                    onClick={() => playChannel(ch)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        playChannel(ch);
                      }
                    }}
                    onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest' })}
                    className="tv-card w-72 shrink-0 sticky left-0 z-10 bg-[#060608] flex items-center gap-3 pr-4 cursor-pointer focus:outline-none rounded-md"
                  >
                    <span className="w-8 text-right font-mono text-xs text-white/40">{(numberOf.get(ch.id) ?? 0).toString().padStart(2, '0')}</span>
                    <ChannelLogo channel={ch} />
                    <span className="text-white text-sm font-semibold truncate">{ch.name}</span>
                  </div>
                  <div className="relative" style={{ width: timelineW }}>
                    {progs.length === 0 && (
                      <div className="absolute inset-y-2 left-1 right-1 rounded-md bg-white/[0.03] flex items-center px-4 text-white/30 text-sm">
                        Sem programação disponível
                      </div>
                    )}
                    {progs.map((p) => {
                      const s = Math.max(Date.parse(p.startUtc), windowStart);
                      const e = Math.min(Date.parse(p.endUtc), windowEnd);
                      const left = (s - windowStart) * pxPerMs;
                      const width = Math.max(24, (e - s) * pxPerMs - 4);
                      const live = Date.parse(p.startUtc) <= now && Date.parse(p.endUtc) >= now;
                      return (
                        <div
                          key={p.id}
                          tabIndex={0}
                          role="button"
                          data-nozoom
                          data-tv-title={`${ch.name}: ${p.title}`}
                          onClick={() => (live ? playChannel(ch) : setSelected({ program: p, channel: ch }))}
                          onKeyDown={(ev) => {
                            if (ev.key === 'Enter') {
                              ev.preventDefault();
                              if (live) playChannel(ch);
                              else setSelected({ program: p, channel: ch });
                            }
                          }}
                          onFocus={(ev) => ev.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
                          className={`tv-card absolute top-2 bottom-2 rounded-md px-3 py-2 overflow-hidden cursor-pointer focus:outline-none ${
                            live ? 'bg-white/[0.14] hover:bg-white/20' : 'bg-white/[0.05] hover:bg-white/10'
                          }`}
                          style={{ left: left + 2, width }}
                        >
                          <p className={`text-sm font-semibold truncate ${live ? 'text-white' : 'text-white/75'}`}>{p.title}</p>
                          <p className="text-xs text-white/45 truncate">
                            {hhmm(p.startUtc)} – {hhmm(p.endUtc)}
                          </p>
                        </div>
                      );
                    })}
                    {nowX >= 0 && nowX <= timelineW && <div className="absolute top-0 bottom-0 w-[2px] bg-[#7C5CFF]/80 pointer-events-none" style={{ left: nowX }} />}
                  </div>
                </div>
              );
            })}
            {hasMore && <div ref={sentinelRef} className="h-10" aria-hidden />}
          </div>
        </div>
      )}

      {/* Programme details */}
      {selected && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8">
          <div className="w-full max-w-xl rounded-2xl bg-[#141418] p-8 space-y-4">
            <p className="text-sm text-white/50">
              {selected.channel.name} · {hhmm(selected.program.startUtc)} – {hhmm(selected.program.endUtc)}
            </p>
            <h2 className="font-display text-3xl font-bold text-white">{selected.program.title}</h2>
            {selected.program.description && <p className="text-white/70 leading-relaxed">{selected.program.description}</p>}
            <div className="flex gap-3 pt-2">
              <button
                autoFocus
                data-autofocus
                onClick={() => {
                  playChannel(selected.channel);
                  setSelected(null);
                }}
                className="tv-card h-12 px-6 rounded-md bg-white text-black font-bold flex items-center gap-2 cursor-pointer focus:outline-none"
              >
                <Play className="w-5 h-5 fill-current" /> Assistir canal
              </button>
              <button onClick={() => setSelected(null)} className="tv-card h-12 px-6 rounded-md bg-white/10 text-white font-semibold cursor-pointer focus:outline-none">
                Fechar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Import */}
      {isImportOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8">
          <div className="w-full max-w-xl rounded-2xl bg-[#141418] p-8 space-y-5 relative">
            <button onClick={() => setIsImportOpen(false)} className="absolute top-5 right-5 w-9 h-9 rounded-full bg-white/10 text-white flex items-center justify-center cursor-pointer" aria-label="Fechar">
              <X className="w-5 h-5" />
            </button>
            <h2 className="font-display text-2xl font-bold text-white">Importar guia de programação</h2>
            <p className="text-sm text-white/50">Listas Xtream e M3U com url-tvg já baixam o guia sozinhas. Use isto para outra fonte XMLTV (aceita .xml.gz).</p>
            <div className="flex gap-2">
              <input
                type="url"
                value={epgUrlInput}
                onChange={(e) => setEpgUrlInput(e.target.value)}
                placeholder="http://servidor/xmltv.php?username=…"
                className="flex-1 bg-black/40 rounded-md px-4 py-3 text-sm text-white outline-none focus:ring-2 focus:ring-white/40"
              />
              <button
                onClick={handleUrlImport}
                disabled={importing || !epgUrlInput.trim()}
                className="tv-card h-12 px-5 rounded-md bg-white text-black font-bold disabled:opacity-40 cursor-pointer focus:outline-none"
              >
                {importing ? 'Baixando…' : 'Baixar'}
              </button>
            </div>
            <label className="block text-sm text-white/60">
              Ou um arquivo XMLTV:
              <input type="file" accept=".xml,.xmltv" onChange={handleFile} className="mt-2 block w-full text-sm text-white/60" />
            </label>
            {importStatus && <p className="text-sm text-[#B9A8FF]">{importStatus}</p>}
          </div>
        </div>
      )}
    </div>
  );
};
