import React, { useEffect, useMemo, useState } from 'react';
import { Play, Plus, Check, Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';
import { SeriesItem } from '../../types';
import { useApp } from '../../context/AppContext';
import { episodeToResume } from '../../data/progress';
import { DetailHero, heroBtn } from '../media/DetailHero';
import { focusIntoView } from '../media/focusIntoView';

interface SeriesDetailModalProps {
  series: SeriesItem;
  onClose: () => void;
}

/** Series title page: hero, seasons and an episode shelf. */
export const SeriesDetailModal: React.FC<SeriesDetailModalProps> = ({ series, onClose }) => {
  const { playEpisode, loadSeriesDetails, getProgressFraction, getResumeSeconds, progressMap, toggleMyList, isInMyList } = useApp();
  const [loading, setLoading] = useState(!series.seasonsLoaded && series.seasons.length === 0);
  const [error, setError] = useState<string | null>(null);
  const [selectedSeasonIdx, setSelectedSeasonIdx] = useState<number | null>(null);
  const inList = isInMyList(series.id);

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
  const hasProgress = series.seasons.some((s) => s.episodes.some((e) => getProgressFraction(e.id) > 0));
  const totalEps = series.seasons.reduce((n, s) => n + s.episodes.length, 0);

  const meta = [
    series.year ? String(series.year) : '',
    series.seasons.length ? `${series.seasons.length} temporada${series.seasons.length > 1 ? 's' : ''}` : '',
    totalEps ? `${totalEps} episódios` : '',
    series.category,
  ].filter(Boolean);

  return (
    <DetailHero
      kind="SÉRIE"
      title={series.title}
      backdropUrl={series.backdropUrl}
      posterUrl={series.posterUrl}
      rating={series.rating}
      meta={meta}
      synopsis={series.overview}
      loading={loading}
      onClose={onClose}
      actions={
        <>
          {resume && (
            <button
              autoFocus
              data-autofocus
              onClick={() => playEpisode(series, resume.seasonNumber, resume.episode)}
              data-tv-title={`${hasProgress ? 'Continuar' : 'Assistir'} T${resume.seasonNumber}:E${resume.episode.episodeNumber}`}
              className={heroBtn.primary}
            >
              <Play className="w-6 h-6 fill-current" />
              {hasProgress ? 'Continuar' : 'Assistir'} T{resume.seasonNumber}:E{resume.episode.episodeNumber}
            </button>
          )}
          <button
            onClick={() => toggleMyList(series.id)}
            data-tv-title={inList ? 'Remover da minha lista' : 'Adicionar à minha lista'}
            title="Minha lista"
            className={heroBtn.round}
          >
            {inList ? <Check className="w-6 h-6" /> : <Plus className="w-6 h-6" />}
          </button>
        </>
      }
    >
      {loading && (
        <div className="flex items-center gap-3 text-white/60 text-lg">
          <Loader2 className="w-6 h-6 animate-spin" /> Carregando temporadas e episódios…
        </div>
      )}
      {!loading && error && series.seasons.length === 0 && (
        <div className="flex items-center gap-3 text-[#FF4D5E] text-lg">
          <AlertCircle className="w-6 h-6" /> {error}
        </div>
      )}
      {!loading && !error && series.seasons.length === 0 && <p className="text-white/50 text-lg">O provedor não informou episódios para esta série.</p>}

      {series.seasons.length > 0 && (
        <section>
          <div className="flex items-center gap-2 overflow-x-auto scrollbar-none pb-2">
            {series.seasons.map((season, idx) => (
              <button
                key={season.seasonNumber}
                data-tv-title={`Temporada: ${season.title}`}
                onClick={() => setSelectedSeasonIdx(idx)}
                onFocus={(e) => e.currentTarget.scrollIntoView({ block: 'nearest', inline: 'nearest' })}
                className={`tv-card shrink-0 h-11 px-5 rounded-full text-base font-semibold cursor-pointer focus:outline-none ${
                  seasonIdx === idx ? 'bg-white text-black' : 'bg-white/10 text-white/80 hover:bg-white/20'
                }`}
              >
                {season.title}
              </button>
            ))}
          </div>

          <div data-shelf className="flex gap-5 overflow-x-auto scrollbar-none scroll-smooth py-6 px-3 -mx-3">
            {activeSeason?.episodes.map((ep) => {
              const frac = getProgressFraction(ep.id);
              const still = ep.stillUrl || series.backdropUrl || series.posterUrl;
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
                  onFocus={(e) => focusIntoView(e.currentTarget)}
                  className="tv-card group w-80 shrink-0 rounded-lg cursor-pointer focus:outline-none"
                >
                  <div className="relative aspect-video rounded-lg overflow-hidden bg-gradient-to-br from-[#2B1F66] to-[#0E0B24]">
                    {still && (
                      <img
                        src={still}
                        alt=""
                        loading="lazy"
                        onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
                        className="absolute inset-0 w-full h-full object-cover"
                      />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />
                    <span className="absolute left-3 bottom-2 font-display text-4xl font-extrabold text-white/90 drop-shadow">{ep.episodeNumber}</span>
                    {frac >= 1 && <CheckCircle2 className="absolute top-2 right-2 w-6 h-6 text-white drop-shadow" />}
                    {frac > 0 && (
                      <div className="absolute bottom-0 inset-x-0 h-1 bg-white/20">
                        <div className="h-full bg-gradient-to-r from-[#7C5CFF] to-[#FF4D8D]" style={{ width: `${Math.min(1, frac) * 100}%` }} />
                      </div>
                    )}
                  </div>
                  <div className="pt-3 px-0.5">
                    <div className="flex items-baseline justify-between gap-3">
                      <h3 className="text-white font-semibold text-base truncate">{ep.title}</h3>
                      {ep.durationMinutes > 0 && <span className="text-white/45 text-sm shrink-0">{ep.durationMinutes} min</span>}
                    </div>
                    {ep.overview && <p className="text-white/55 text-sm leading-snug line-clamp-2 mt-1">{ep.overview}</p>}
                    {getResumeSeconds(ep.id) > 0 && frac < 1 && <p className="text-[#B9A8FF] text-xs mt-1">Continuar de onde parou</p>}
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      )}
    </DetailHero>
  );
};
