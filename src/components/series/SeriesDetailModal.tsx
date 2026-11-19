import React, { useEffect, useMemo, useState } from 'react';
import { X, Play, Star, Clock, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';
import { SeriesItem } from '../../types';
import { useApp } from '../../context/AppContext';
import { episodeToResume } from '../../data/progress';

interface SeriesDetailModalProps {
  series: SeriesItem;
  onClose: () => void;
}

export const SeriesDetailModal: React.FC<SeriesDetailModalProps> = ({ series, onClose }) => {
  const { playEpisode, loadSeriesDetails, getProgressFraction, getResumeSeconds, progressMap } = useApp();
  const [loading, setLoading] = useState(!series.seasonsLoaded && series.seasons.length === 0);
  const [error, setError] = useState<string | null>(null);
  const [selectedSeasonIdx, setSelectedSeasonIdx] = useState<number | null>(null);

  useEffect(() => {
    let alive = true;
    loadSeriesDetails(series)
      .catch((e) => alive && setError((e as Error).message || 'Falha ao carregar episódios.'))
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [series.id]);

  const resume = useMemo(() => episodeToResume(series, progressMap), [series, progressMap]);

  const defaultSeasonIdx = Math.max(0, series.seasons.findIndex((s) => s.seasonNumber === resume?.seasonNumber));
  const seasonIdx = selectedSeasonIdx ?? defaultSeasonIdx;
  const activeSeason = series.seasons[seasonIdx];
  const hasProgress = !!resume && (getResumeSeconds(resume.episode.id) > 0 || series.seasons.some((s) => s.episodes.some((e) => getProgressFraction(e.id) > 0)));

  return (
    <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-4xl bg-[#16162A] border border-[#2A2A45] rounded-3xl overflow-hidden shadow-2xl relative max-h-[90vh] flex flex-col">
        <button
          onClick={onClose}
          data-tv-title="Fechar detalhes da série"
          className="tv-card absolute top-4 right-4 z-20 w-9 h-9 rounded-full bg-black/60 hover:bg-black/80 text-white flex items-center justify-center cursor-pointer focus:outline-none"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="relative h-52 md:h-64 w-full bg-black shrink-0">
          {(series.backdropUrl || series.posterUrl) && (
            <img src={series.backdropUrl || series.posterUrl} alt="" onError={(e) => ((e.target as HTMLElement).style.display = 'none')} className="w-full h-full object-cover opacity-60" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-[#16162A] via-[#16162A]/40 to-transparent" />
          <div className="absolute bottom-4 left-6 right-6 space-y-3">
            <div className="flex flex-wrap items-center gap-2 text-xs text-[#A8A6C0]">
              {series.rating > 0 && (
                <span className="flex items-center gap-1 text-[#FF6F91] font-bold">
                  <Star className="w-3.5 h-3.5 fill-current" /> {series.rating} / 10
                </span>
              )}
              <span className="text-[#1FCFAE] font-semibold">{series.category}</span>
              {series.seasons.length > 0 && <span>• {series.seasons.length} temporada(s)</span>}
            </div>
            <h2 className="text-2xl md:text-3xl font-black text-white">{series.title}</h2>
            {resume && (
              <button
                autoFocus
                onClick={() => playEpisode(series, resume.seasonNumber, resume.episode)}
                data-tv-title={`${hasProgress ? 'Continuar' : 'Assistir'} T${resume.seasonNumber}:E${resume.episode.episodeNumber}`}
                className="tv-card px-6 py-3 rounded-2xl bg-white text-[#07070F] font-bold text-sm flex items-center gap-2.5 cursor-pointer focus:outline-none"
              >
                <Play className="w-5 h-5 fill-current" />
                {hasProgress ? 'Continuar' : 'Assistir'} T{resume.seasonNumber}:E{resume.episode.episodeNumber}
              </button>
            )}
          </div>
        </div>

        {series.overview && <div className="px-6 py-3 border-b border-[#2A2A45]/60 text-xs text-[#C9C7DA] leading-relaxed line-clamp-4">{series.overview}</div>}

        {loading && (
          <div className="p-10 flex items-center justify-center gap-3 text-sm text-[#A8A6C0]">
            <Loader2 className="w-5 h-5 animate-spin" /> Carregando temporadas e episódios…
          </div>
        )}
        {!loading && error && series.seasons.length === 0 && (
          <div className="p-8 flex items-center justify-center gap-2 text-sm text-[#FF5468]">
            <AlertCircle className="w-5 h-5" /> {error}
          </div>
        )}
        {!loading && !error && series.seasons.length === 0 && (
          <div className="p-8 text-center text-sm text-[#A8A6C0]">O provedor não informou episódios para esta série.</div>
        )}

        {series.seasons.length > 0 && (
          <>
            <div className="px-6 py-3 bg-[#07070F]/50 border-b border-[#2A2A45] flex items-center gap-2 overflow-x-auto shrink-0">
              {series.seasons.map((season, idx) => (
                <button
                  key={season.seasonNumber}
                  data-tv-title={`Temporada: ${season.title}`}
                  onClick={() => setSelectedSeasonIdx(idx)}
                  onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
                  className={`tv-card px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap focus:outline-none ${
                    seasonIdx === idx ? 'bg-[#6B4FE0] text-white' : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border border-[#2A2A45]'
                  }`}
                >
                  {season.title}
                </button>
              ))}
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-3">
              {activeSeason?.episodes.map((ep) => {
                const frac = getProgressFraction(ep.id);
                return (
                  <div
                    key={ep.id}
                    tabIndex={0}
                    role="button"
                    data-tv-title={`Episódio ${ep.episodeNumber}: ${ep.title}`}
                    onClick={() => playEpisode(series, activeSeason.seasonNumber, ep)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        playEpisode(series, activeSeason.seasonNumber, ep);
                      }
                    }}
                    onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest' })}
                    className="tv-card p-3 rounded-2xl bg-[#07070F]/80 hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] cursor-pointer flex items-center gap-4 group focus:outline-none"
                  >
                    <div className="w-28 h-16 rounded-xl bg-black/40 overflow-hidden relative shrink-0 border border-white/5">
                      {(ep.stillUrl || series.posterUrl) && (
                        <img src={ep.stillUrl || series.posterUrl} alt="" loading="lazy" onError={(e) => ((e.target as HTMLElement).style.display = 'none')} className="w-full h-full object-cover" />
                      )}
                      <div className="absolute inset-0 bg-black/30 flex items-center justify-center opacity-0 group-hover:opacity-100">
                        <Play className="w-5 h-5 text-white fill-current" />
                      </div>
                      {frac > 0 && (
                        <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/60">
                          <div className="h-full bg-[#FF5468]" style={{ width: `${frac * 100}%` }} />
                        </div>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono font-bold text-[#B9A8FF]">EP {ep.episodeNumber}</span>
                        <h4 className="text-sm font-bold text-white truncate">{ep.title}</h4>
                        {frac >= 1 && <CheckCircle2 className="w-4 h-4 text-[#1FCFAE] shrink-0" />}
                      </div>
                      {ep.overview && <p className="text-[11px] text-[#A8A6C0] line-clamp-2 mt-0.5">{ep.overview}</p>}
                    </div>
                    {ep.durationMinutes > 0 && (
                      <span className="text-[11px] font-mono text-[#A8A6C0] flex items-center gap-1 shrink-0">
                        <Clock className="w-3 h-3" /> {ep.durationMinutes} min
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </div>
  );
};
