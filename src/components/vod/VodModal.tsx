import React, { useEffect, useState } from 'react';
import { Play, RotateCcw, Plus, Check } from 'lucide-react';
import { VodItem } from '../../types';
import { useApp } from '../../context/AppContext';
import { DetailHero, heroBtn } from '../media/DetailHero';
import { MediaRow } from '../media/MediaRow';
import { PosterCard } from '../media/PosterCard';

interface VodModalProps {
  vod: VodItem;
  onClose: () => void;
}

function clock(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h > 0 ? `${h}h${m.toString().padStart(2, '0')}` : `${m} min`;
}

function duration(min: number) {
  const h = Math.floor(min / 60);
  const m = min % 60;
  return h > 0 ? `${h}h ${m.toString().padStart(2, '0')}min` : `${m}min`;
}

/** Movie title page. */
export const VodModal: React.FC<VodModalProps> = ({ vod, onClose }) => {
  const { playVod, loadVodDetails, getResumeSeconds, getProgressFraction, toggleMyList, isInMyList, vodItems, setSelectedVodModal } = useApp();
  const [loading, setLoading] = useState(false);
  const resumeAt = getResumeSeconds(vod.id);
  const fraction = getProgressFraction(vod.id);
  const inList = isInMyList(vod.id);

  useEffect(() => {
    let alive = true;
    setLoading(true);
    loadVodDetails(vod)
      .catch(() => undefined)
      .finally(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
    // Load once per opened title; the page re-renders with enriched data.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vod.id]);

  // "Títulos semelhantes": same category, best rated first.
  const similar = React.useMemo(
    () => vodItems.filter((v) => v.category === vod.category && v.id !== vod.id).sort((a, b) => b.rating - a.rating).slice(0, 14),
    [vodItems, vod.category, vod.id]
  );

  const meta = [vod.year ? String(vod.year) : '', vod.durationMinutes ? duration(vod.durationMinutes) : '', vod.category].filter(Boolean);
  const credits = [
    vod.cast && vod.cast.length ? { label: 'Elenco', value: vod.cast.join(', ') } : null,
    vod.director ? { label: 'Direção', value: vod.director } : null,
  ].filter((c): c is { label: string; value: string } => !!c);

  return (
    <DetailHero
      kind="FILME"
      title={vod.title}
      backdropUrl={vod.backdropUrl}
      posterUrl={vod.posterUrl}
      rating={vod.rating}
      meta={meta}
      synopsis={vod.description}
      credits={credits}
      loading={loading}
      onClose={onClose}
      actions={
        <>
          <button
            autoFocus
            data-autofocus
            onClick={() => playVod(vod)}
            data-tv-title={resumeAt ? `Continuar ${vod.title}` : `Assistir ${vod.title}`}
            className={heroBtn.primary}
          >
            <Play className="w-6 h-6 fill-current" />
            {resumeAt ? `Continuar de ${clock(resumeAt)}` : 'Assistir'}
          </button>
          {resumeAt > 0 && (
            <button onClick={() => playVod(vod, true)} data-tv-title="Assistir do início" className={heroBtn.secondary}>
              <RotateCcw className="w-5 h-5" /> Do início
            </button>
          )}
          <button
            onClick={() => toggleMyList(vod.id)}
            data-tv-title={inList ? 'Remover da minha lista' : 'Adicionar à minha lista'}
            title="Minha lista"
            className={heroBtn.round}
          >
            {inList ? <Check className="w-6 h-6" /> : <Plus className="w-6 h-6" />}
          </button>
          {fraction > 0 && fraction < 1 && (
            <div className="basis-full max-w-sm mt-1 h-1 rounded-full bg-white/20 overflow-hidden">
              <div className="h-full bg-gradient-to-r from-[#7C5CFF] to-[#FF4D8D]" style={{ width: `${fraction * 100}%` }} />
            </div>
          )}
        </>
      }
    >
      {similar.length > 0 && (
        <MediaRow title="Títulos semelhantes">
          {similar.map((v) => (
            <PosterCard key={v.id} title={v.title} subtitle={v.category} imageUrl={v.posterUrl} progress={getProgressFraction(v.id)} onSelect={() => setSelectedVodModal(v)} />
          ))}
        </MediaRow>
      )}
    </DetailHero>
  );
};
