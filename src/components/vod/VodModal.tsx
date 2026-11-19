import React, { useEffect, useState } from 'react';
import { X, Play, Star, Clock, Calendar, RotateCcw, Loader2 } from 'lucide-react';
import { VodItem } from '../../types';
import { useApp } from '../../context/AppContext';

interface VodModalProps {
  vod: VodItem;
  onClose: () => void;
}

function fmt(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h > 0 ? `${h}h${m.toString().padStart(2, '0')}` : `${m} min`;
}

export const VodModal: React.FC<VodModalProps> = ({ vod, onClose }) => {
  const { playVod, loadVodDetails, getResumeSeconds, getProgressFraction } = useApp();
  const [loading, setLoading] = useState(false);
  const resumeAt = getResumeSeconds(vod.id);
  const fraction = getProgressFraction(vod.id);

  useEffect(() => {
    let alive = true;
    setLoading(true);
    loadVodDetails(vod)
      .catch(() => undefined)
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
    // Load once per opened title; the modal re-renders with enriched data.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vod.id]);

  return (
    <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-3xl bg-[#16162A] border border-[#2A2A45] rounded-3xl overflow-hidden shadow-2xl relative max-h-[90vh] flex flex-col">
        <button
          onClick={onClose}
          data-tv-title="Fechar detalhes do filme"
          className="tv-card absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-black/80 text-white flex items-center justify-center cursor-pointer focus:outline-none"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="relative h-56 md:h-72 w-full bg-black shrink-0">
          {(vod.backdropUrl || vod.posterUrl) && (
            <img src={vod.backdropUrl || vod.posterUrl} alt="" onError={(e) => ((e.target as HTMLElement).style.display = 'none')} className="w-full h-full object-cover opacity-60" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-[#16162A] via-[#16162A]/40 to-transparent" />
          <div className="absolute bottom-5 left-6 right-6 flex flex-wrap items-center gap-3">
            <button
              onClick={() => playVod(vod)}
              autoFocus
              data-tv-title={resumeAt ? `Continuar ${vod.title}` : `Assistir ${vod.title}`}
              className="tv-card px-6 py-3 rounded-2xl bg-white text-[#07070F] font-bold text-sm flex items-center gap-2.5 cursor-pointer focus:outline-none"
            >
              <Play className="w-5 h-5 fill-current" />
              {resumeAt ? `Continuar de ${fmt(resumeAt)}` : 'Assistir'}
            </button>
            {resumeAt > 0 && (
              <button
                onClick={() => playVod(vod, true)}
                data-tv-title="Assistir do início"
                className="tv-card px-5 py-3 rounded-2xl bg-white/15 text-white font-semibold text-sm flex items-center gap-2 cursor-pointer focus:outline-none"
              >
                <RotateCcw className="w-4 h-4" /> Do início
              </button>
            )}
            {loading && <Loader2 className="w-5 h-5 text-white/70 animate-spin" />}
          </div>
          {fraction > 0 && fraction < 1 && (
            <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/10">
              <div className="h-full bg-[#FF5468]" style={{ width: `${fraction * 100}%` }} />
            </div>
          )}
        </div>

        <div className="p-6 pt-3 space-y-4 overflow-y-auto">
          <div>
            <div className="flex flex-wrap items-center gap-3 text-xs text-[#A8A6C0] mb-1.5">
              {vod.rating > 0 && (
                <span className="flex items-center gap-1 text-[#FF6F91] font-bold">
                  <Star className="w-3.5 h-3.5 fill-current" /> {vod.rating} / 10
                </span>
              )}
              {vod.year > 0 && (
                <span className="flex items-center gap-1">
                  <Calendar className="w-3.5 h-3.5" /> {vod.year}
                </span>
              )}
              {vod.durationMinutes > 0 && (
                <span className="flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" /> {vod.durationMinutes} min
                </span>
              )}
              <span className="px-2 py-0.5 rounded-md bg-[#6B4FE0]/20 text-[#B9A8FF] font-semibold">{vod.category}</span>
            </div>
            <h2 className="text-2xl font-black text-white">{vod.title}</h2>
          </div>

          <p className="text-sm text-[#C9C7DA] leading-relaxed">{vod.description || (loading ? 'Carregando sinopse…' : 'Sinopse não informada pelo provedor.')}</p>

          {(vod.director || (vod.cast && vod.cast.length > 0)) && (
            <div className="pt-2 border-t border-[#2A2A45]/60 grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
              {vod.director && (
                <div>
                  <span className="text-[#A8A6C0] block text-[10px] uppercase font-bold tracking-wider">Direção</span>
                  <span className="text-white font-medium">{vod.director}</span>
                </div>
              )}
              {vod.cast && vod.cast.length > 0 && (
                <div>
                  <span className="text-[#A8A6C0] block text-[10px] uppercase font-bold tracking-wider">Elenco</span>
                  <span className="text-white font-medium">{vod.cast.join(', ')}</span>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
