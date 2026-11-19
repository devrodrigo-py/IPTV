import React, { useState } from 'react';
import { Play, Info, Plus, Check, Star } from 'lucide-react';
import { SeriesItem, VodItem } from '../../types';
import { NebulaMark } from '../brand/NebulaLogo';

type Featured = VodItem | SeriesItem;
const isVod = (x: Featured): x is VodItem => 'streamUrl' in x;

function duration(min: number) {
  const h = Math.floor(min / 60);
  const m = min % 60;
  return h > 0 ? `${h}h ${m.toString().padStart(2, '0')}min` : `${m}min`;
}

interface BillboardProps {
  item: Featured;
  resumeSeconds: number;
  inMyList: boolean;
  onPlay: () => void;
  onInfo: () => void;
  onToggleList: () => void;
  /** 'tv': fixed-height top area (rows scroll below it); 'page': scrolls with the page. */
  layout?: 'tv' | 'page';
}

/**
 * Full-bleed billboard at the top of Home. Uses the backdrop when there is
 * one; with only a poster (typical of provider lists) it shows the poster
 * crisp on the right over a blurred, enlarged copy of itself.
 */
export const Billboard: React.FC<BillboardProps> = ({ item, resumeSeconds, inMyList, onPlay, onInfo, onToggleList, layout = 'page' }) => {
  const tv = layout === 'tv';
  const [backdropBroken, setBackdropBroken] = useState<string | null>(null);
  const [posterBroken, setPosterBroken] = useState<string | null>(null);
  const backdrop = item.backdropUrl && backdropBroken !== item.backdropUrl ? item.backdropUrl : undefined;
  const poster = item.posterUrl && posterBroken !== item.posterUrl ? item.posterUrl : undefined;
  const vod = isVod(item);

  const meta: string[] = [];
  const year = vod ? item.year : item.year;
  if (year) meta.push(String(year));
  if (vod && item.durationMinutes > 0) meta.push(duration(item.durationMinutes));
  if (!vod && item.seasons.length > 0) meta.push(`${item.seasons.length} temporada${item.seasons.length > 1 ? 's' : ''}`);
  if (item.category) meta.push(item.category);
  const synopsis = vod ? item.description : item.overview;

  return (
    <section className={tv ? 'relative h-[54vh] shrink-0' : 'relative h-[86vh] min-h-[560px] overflow-hidden'} aria-label={item.title}>
      {/* Art (on TV it spans the whole screen behind the rows) */}
      <div key={item.id} className={`${tv ? 'absolute inset-x-0 top-0 h-screen' : 'absolute inset-0'} animate-[billboardIn_700ms_ease] pointer-events-none`}>
        {backdrop ? (
          <img
            src={backdrop}
            alt=""
            onError={() => setBackdropBroken(backdrop)}
            className="absolute inset-0 w-full h-full object-cover object-top"
          />
        ) : poster ? (
          <>
            <img src={poster} alt="" aria-hidden className="absolute inset-0 w-full h-full object-cover scale-125 blur-3xl opacity-60" />
            <img
              src={poster}
              alt=""
              onError={() => setPosterBroken(poster)}
              className="absolute right-[7%] top-[10%] h-[58%] rounded-xl shadow-[0_30px_80px_rgba(0,0,0,0.8)] object-cover"
              style={{ aspectRatio: '2 / 3' }}
            />
          </>
        ) : (
          <div className="absolute inset-0 bg-[radial-gradient(70%_80%_at_75%_30%,rgba(124,92,255,0.35),rgba(255,77,141,0.12)_45%,transparent_75%)]" />
        )}
        {/* Readability scrims */}
        <div className="absolute inset-0 bg-gradient-to-r from-[#060608] via-[#060608]/75 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-[#060608] via-[#060608]/70 to-transparent" />
      </div>

      {/* Info */}
      <div key={`${item.id}-info`} className={`absolute left-14 ${tv ? 'bottom-[3vh] space-y-4' : 'bottom-[24vh] space-y-5'} max-w-[46%] animate-[billboardTextIn_600ms_ease]`}>
        <span className="flex items-center gap-2.5 text-[13px] font-bold tracking-[0.28em] text-white/80">
          <NebulaMark size={22} />
          {vod ? 'FILME' : 'SÉRIE'}
        </span>
        <h1 className={`font-display ${tv ? 'text-[56px]' : 'text-[64px]'} font-extrabold text-white leading-[0.98] tracking-tight line-clamp-2 drop-shadow-[0_4px_24px_rgba(0,0,0,0.6)]`}>
          {item.title}
        </h1>
        {(meta.length > 0 || item.rating > 0) && (
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[17px] text-white/80 font-medium">
            {item.rating > 0 && (
              <span className="flex items-center gap-1 text-white">
                <Star className="w-4 h-4 fill-[#FFC94D] text-[#FFC94D]" /> {item.rating.toFixed(1)}
              </span>
            )}
            {meta.map((m, i) => (
              <React.Fragment key={m + i}>
                {(i > 0 || item.rating > 0) && <span className="text-white/35">•</span>}
                <span>{m}</span>
              </React.Fragment>
            ))}
          </div>
        )}
        {synopsis && <p className={`text-lg text-white/75 leading-relaxed ${tv ? 'line-clamp-2' : 'line-clamp-3'}`}>{synopsis}</p>}
        <div className="flex items-center gap-3 pt-2">
          <button
            data-autofocus
            onClick={onPlay}
            data-tv-title={`${resumeSeconds > 0 ? 'Continuar' : 'Assistir'} ${item.title}`}
            className="tv-card h-14 px-9 rounded-md bg-white text-black font-bold text-lg flex items-center gap-3 cursor-pointer focus:outline-none hover:bg-white/85"
          >
            <Play className="w-6 h-6 fill-current" /> {resumeSeconds > 0 ? 'Continuar' : 'Assistir'}
          </button>
          <button
            onClick={onInfo}
            data-tv-title={`Mais informações: ${item.title}`}
            className="tv-card h-14 px-7 rounded-md bg-white/20 text-white font-semibold text-lg flex items-center gap-3 cursor-pointer focus:outline-none hover:bg-white/30"
          >
            <Info className="w-6 h-6" /> Mais informações
          </button>
          <button
            onClick={onToggleList}
            data-tv-title={inMyList ? 'Remover da minha lista' : 'Adicionar à minha lista'}
            title="Minha lista"
            className="tv-card w-14 h-14 rounded-full border-2 border-white/50 text-white flex items-center justify-center cursor-pointer focus:outline-none hover:border-white"
          >
            {inMyList ? <Check className="w-6 h-6" /> : <Plus className="w-6 h-6" />}
          </button>
        </div>
      </div>
    </section>
  );
};
