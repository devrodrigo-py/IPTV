import React, { useState } from 'react';
import { X, Star } from 'lucide-react';
import { NebulaMark } from '../brand/NebulaLogo';

interface DetailHeroProps {
  kind: 'FILME' | 'SÉRIE';
  title: string;
  backdropUrl?: string;
  posterUrl?: string;
  rating?: number;
  meta: string[];
  synopsis?: string;
  credits?: { label: string; value: string }[];
  actions: React.ReactNode;
  onClose: () => void;
  /** Content under the hero (seasons and episodes). */
  children?: React.ReactNode;
  loading?: boolean;
}

/** Full-screen title page shared by movies and series. */
export const DetailHero: React.FC<DetailHeroProps> = ({
  kind,
  title,
  backdropUrl,
  posterUrl,
  rating,
  meta,
  synopsis,
  credits,
  actions,
  onClose,
  children,
  loading,
}) => {
  const [bdBroken, setBdBroken] = useState(false);
  const [posterBroken, setPosterBroken] = useState(false);
  const backdrop = backdropUrl && !bdBroken ? backdropUrl : undefined;
  const poster = posterUrl && !posterBroken ? posterUrl : undefined;

  return (
    <div className="fixed inset-0 z-50 bg-[#060608] overflow-y-auto scrollbar-none animate-[billboardTextIn_300ms_ease]">
      <div className="absolute inset-x-0 top-0 h-screen pointer-events-none" aria-hidden>
        {backdrop ? (
          <img src={backdrop} alt="" onError={() => setBdBroken(true)} className="absolute inset-0 w-full h-full object-cover object-top" />
        ) : poster ? (
          <>
            <img src={poster} alt="" className="absolute inset-0 w-full h-full object-cover scale-125 blur-3xl opacity-50" />
            <img
              src={poster}
              alt=""
              onError={() => setPosterBroken(true)}
              className="absolute right-[7%] top-[12%] h-[56%] rounded-xl object-cover shadow-[0_30px_80px_rgba(0,0,0,0.8)]"
            />
          </>
        ) : (
          <div className="absolute inset-0 bg-[radial-gradient(70%_80%_at_75%_25%,rgba(124,92,255,0.3),rgba(255,77,141,0.1)_45%,transparent_75%)]" />
        )}
        <div className="absolute inset-0 bg-gradient-to-r from-[#060608] via-[#060608]/80 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 h-2/3 bg-gradient-to-t from-[#060608] via-[#060608]/80 to-transparent" />
      </div>

      <button
        onClick={onClose}
        data-tv-skip
        tabIndex={-1}
        aria-label="Fechar"
        className="fixed top-6 right-8 z-10 w-11 h-11 rounded-full bg-black/50 hover:bg-black/80 text-white flex items-center justify-center cursor-pointer"
      >
        <X className="w-6 h-6" />
      </button>

      <div className="relative px-14 pt-[13vh] pb-12">
        <div className="max-w-[48%] space-y-5">
          <span className="flex items-center gap-2.5 text-[13px] font-bold tracking-[0.28em] text-white/80">
            <NebulaMark size={22} />
            {kind}
          </span>
          <h1 className="font-display text-[60px] font-extrabold text-white leading-[0.98] tracking-tight drop-shadow-[0_4px_24px_rgba(0,0,0,0.6)]">
            {title}
          </h1>
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-[17px] text-white/80 font-medium">
            {!!rating && rating > 0 && (
              <span className="flex items-center gap-1 text-white">
                <Star className="w-4 h-4 fill-[#FFC94D] text-[#FFC94D]" /> {rating.toFixed(1)}
              </span>
            )}
            {meta.map((m, i) => (
              <React.Fragment key={m + i}>
                {(i > 0 || (!!rating && rating > 0)) && <span className="text-white/35">•</span>}
                <span>{m}</span>
              </React.Fragment>
            ))}
          </div>
          <p className="text-lg text-white/80 leading-relaxed line-clamp-4 min-h-[1.5em]">
            {synopsis || (loading ? 'Carregando informações…' : 'Sinopse não informada pelo provedor.')}
          </p>
          <div className="flex flex-wrap items-center gap-3 pt-2">{actions}</div>
          {credits && credits.length > 0 && (
            <div className="pt-2 space-y-1 text-[15px]">
              {credits.map((c) => (
                <p key={c.label} className="text-white/50 line-clamp-1">
                  <span className="text-white/35">{c.label}: </span>
                  <span className="text-white/75">{c.value}</span>
                </p>
              ))}
            </div>
          )}
        </div>
        {children && <div className="mt-12">{children}</div>}
      </div>
    </div>
  );
};

/** Primary/secondary/round button styles used on title pages. */
export const heroBtn = {
  primary: 'tv-card h-14 px-9 rounded-md bg-white text-black font-bold text-lg flex items-center gap-3 cursor-pointer focus:outline-none hover:bg-white/85',
  secondary: 'tv-card h-14 px-7 rounded-md bg-white/20 text-white font-semibold text-lg flex items-center gap-3 cursor-pointer focus:outline-none hover:bg-white/30',
  round: 'tv-card w-14 h-14 rounded-full border-2 border-white/50 text-white flex items-center justify-center cursor-pointer focus:outline-none hover:border-white',
};
