import React, { useMemo, useState } from 'react';
import { Heart, Search, Tv } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Channel, EpgProgram } from '../types';
import { useProgressiveList } from '../hooks/useProgressiveList';

function hhmm(iso: string) {
  const d = new Date(iso);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

function nowAndNext(list: EpgProgram[], now = Date.now()): { now?: EpgProgram; next?: EpgProgram; pct: number } {
  for (let i = 0; i < list.length; i++) {
    const s = Date.parse(list[i].startUtc);
    const e = Date.parse(list[i].endUtc);
    if (s <= now && e >= now) return { now: list[i], next: list[i + 1], pct: e > s ? ((now - s) / (e - s)) * 100 : 0 };
    if (s > now) return { next: list[i], pct: 0 };
  }
  return { pct: 0 };
}

const Logo: React.FC<{ channel: Channel; className?: string }> = ({ channel, className = '' }) => {
  const [broken, setBroken] = useState(false);
  return (
    <div className={`relative rounded-md bg-gradient-to-br from-[#1C1C22] to-[#0E0E12] overflow-hidden ${className}`}>
      {channel.logoUrl && !broken ? (
        <img src={channel.logoUrl} alt="" loading="lazy" onError={() => setBroken(true)} className="absolute inset-0 w-full h-full object-contain p-[12%]" />
      ) : (
        <div className="absolute inset-0 flex items-center justify-center px-2">
          <span className="font-display font-bold text-white/70 text-center text-sm leading-tight line-clamp-2">{channel.name}</span>
        </div>
      )}
    </div>
  );
};

const ALL = '__all__';
const FAVS = '__favs__';

/** Live TV: focused-channel panel, categories and a now/next channel guide. */
export const ChannelsView: React.FC = () => {
  const { filteredChannels, categories, favorites, playChannel, getChannelPrograms, tvMode } = useApp();
  const [category, setCategory] = useState<string>(ALL);
  const [query, setQuery] = useState('');
  const [focusedId, setFocusedId] = useState<string | null>(null);

  const numberOf = useMemo(() => new Map(filteredChannels.map((c, i) => [c.id, i + 1])), [filteredChannels]);
  const favSet = useMemo(() => new Set(favorites), [favorites]);
  const counts = useMemo(() => {
    const m = new Map<string, number>();
    for (const c of filteredChannels) m.set(c.groupTitle || 'Geral', (m.get(c.groupTitle || 'Geral') ?? 0) + 1);
    return m;
  }, [filteredChannels]);

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    return filteredChannels.filter((c) => {
      if (category === FAVS && !favSet.has(c.id)) return false;
      if (category !== ALL && category !== FAVS && (c.groupTitle || 'Geral') !== category) return false;
      return !q || c.name.toLowerCase().includes(q);
    });
  }, [filteredChannels, category, favSet, query]);

  const { visible, hasMore, sentinelRef } = useProgressiveList(list, 40);
  const focused = list.find((c) => c.id === focusedId) ?? list[0];
  const focusedEpg = focused ? nowAndNext(getChannelPrograms(focused.id)) : { pct: 0 };

  const cats: { id: string; label: string; count: number }[] = [
    { id: ALL, label: 'Todos os canais', count: filteredChannels.length },
    { id: FAVS, label: 'Favoritos', count: favorites.length },
    ...categories.map((c) => ({ id: c, label: c, count: counts.get(c) ?? 0 })),
  ];

  if (filteredChannels.length === 0) {
    return (
      <div className="h-full flex flex-col items-center justify-center text-center px-10 gap-4">
        <Tv className="w-14 h-14 text-white/20" strokeWidth={1.3} />
        <h1 className="font-display text-3xl font-bold text-white">Nenhum canal ao vivo</h1>
        <p className="text-white/60 max-w-md">Adicione uma lista em Mais › Minhas listas para ver seus canais aqui.</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col overflow-hidden select-none">
      {/* Focused channel */}
      <section className="relative shrink-0 h-[34vh] px-14 pt-10 flex gap-8 items-end pb-6 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(60%_90%_at_80%_0%,rgba(124,92,255,0.18),transparent_70%)] pointer-events-none" />
        {focused && (
          <>
            <Logo channel={focused} className="relative w-56 aspect-video shrink-0 shadow-2xl" />
            <div className="relative min-w-0 flex-1 space-y-2">
              <div className="flex items-center gap-3 text-sm font-semibold text-white/70">
                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded bg-[#FF3B4E] text-white text-xs font-bold tracking-wider">AO VIVO</span>
                <span className="font-mono">{(numberOf.get(focused.id) ?? 0).toString().padStart(2, '0')}</span>
                <span className="truncate">{focused.name}</span>
              </div>
              <h1 className="font-display text-[40px] leading-tight font-extrabold text-white truncate">
                {focusedEpg.now?.title || focused.name}
              </h1>
              <div className="flex items-center gap-4 text-white/70 text-base">
                {focusedEpg.now ? (
                  <>
                    <span>
                      {hhmm(focusedEpg.now.startUtc)} – {hhmm(focusedEpg.now.endUtc)}
                    </span>
                    <span className="w-48 h-1 rounded-full bg-white/15 overflow-hidden">
                      <span className="block h-full bg-white" style={{ width: `${focusedEpg.pct}%` }} />
                    </span>
                  </>
                ) : (
                  <span>{focused.groupTitle || 'Ao vivo'}</span>
                )}
                {focusedEpg.next && (
                  <span className="truncate text-white/50">
                    A seguir: {hhmm(focusedEpg.next.startUtc)} {focusedEpg.next.title}
                  </span>
                )}
              </div>
              {focusedEpg.now?.description && <p className="text-white/55 text-sm line-clamp-2 max-w-3xl">{focusedEpg.now.description}</p>}
            </div>
          </>
        )}
      </section>

      <div className="flex-1 min-h-0 flex gap-8 px-14">
        {/* Categories */}
        <nav className="w-64 shrink-0 overflow-y-auto scrollbar-none pb-10 space-y-1" aria-label="Categorias">
          {!tvMode && (
            <div className="relative mb-3">
              <Search className="w-4 h-4 text-white/40 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Filtrar canais"
                className="w-full bg-white/5 text-sm text-white placeholder-white/40 pl-9 pr-3 py-2.5 rounded-md outline-none focus:bg-white/10"
              />
            </div>
          )}
          {cats.map((c) => (
            <button
              key={c.id}
              onClick={() => setCategory(c.id)}
              onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest' })}
              data-tv-title={`Categoria: ${c.label}`}
              className={`tv-card w-full flex items-center justify-between gap-3 px-4 h-12 rounded-md text-left cursor-pointer focus:outline-none ${
                category === c.id ? 'bg-white/10 text-white font-semibold' : 'text-white/60 hover:text-white'
              }`}
            >
              <span className="truncate flex items-center gap-2">
                {c.id === FAVS && <Heart className="w-4 h-4" />}
                {c.label}
              </span>
              <span className="text-xs text-white/40 font-mono">{c.count}</span>
            </button>
          ))}
        </nav>

        {/* Guide */}
        <div className="flex-1 min-w-0 overflow-y-auto scrollbar-none pb-10 space-y-2">
          {list.length === 0 && <p className="text-white/50 pt-6">{category === FAVS ? 'Marque canais como favoritos no player para vê-los aqui.' : 'Nenhum canal encontrado.'}</p>}
          {visible.map((ch, idx) => {
            const epg = nowAndNext(getChannelPrograms(ch.id));
            return (
              <div
                key={ch.id}
                tabIndex={0}
                role="button"
                data-autofocus={idx === 0 ? true : undefined}
                data-tv-title={`Canal: ${ch.name}`}
                onClick={() => playChannel(ch, list)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    playChannel(ch, list);
                  }
                }}
                onFocus={(e) => {
                  setFocusedId(ch.id);
                  e.currentTarget.scrollIntoView({ block: 'nearest' });
                }}
                onMouseEnter={() => setFocusedId(ch.id)}
                data-nozoom
                className="tv-card flex items-center gap-5 h-[84px] px-4 rounded-lg bg-white/[0.03] hover:bg-white/[0.07] focus:bg-white/[0.1] cursor-pointer focus:outline-none"
              >
                <span className="w-10 text-right font-mono text-sm text-white/40 shrink-0">{(numberOf.get(ch.id) ?? 0).toString().padStart(2, '0')}</span>
                <Logo channel={ch} className="w-[104px] aspect-video shrink-0" />
                <div className="min-w-0 w-44 shrink-0">
                  <p className="text-white font-semibold truncate flex items-center gap-2">
                    {ch.name}
                    {favSet.has(ch.id) && <Heart className="w-3.5 h-3.5 text-[#FF4D8D] fill-current shrink-0" />}
                  </p>
                  <p className="text-white/40 text-xs truncate mt-0.5">{ch.groupTitle || 'Geral'}</p>
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-white/85 truncate">{epg.now ? epg.now.title : 'Programação não disponível'}</p>
                  <div className="flex items-center gap-3 mt-1.5">
                    {epg.now && <span className="text-xs text-white/45 shrink-0">{hhmm(epg.now.startUtc)}</span>}
                    <span className="flex-1 max-w-[320px] h-[3px] rounded-full bg-white/10 overflow-hidden">
                      {epg.pct > 0 && <span className="block h-full bg-white/80" style={{ width: `${epg.pct}%` }} />}
                    </span>
                    {epg.now && <span className="text-xs text-white/45 shrink-0">{hhmm(epg.now.endUtc)}</span>}
                  </div>
                </div>
              </div>
            );
          })}
          {hasMore && <div ref={sentinelRef} className="h-10" aria-hidden />}
        </div>
      </div>
    </div>
  );
};
