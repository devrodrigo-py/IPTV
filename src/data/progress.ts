import { ProgressEntry, SeriesItem, Episode, WatchHistoryItem } from '../types';

/** Below this many seconds we start from the beginning instead of resuming. */
export const MIN_RESUME_SECONDS = 30;
/** Past this fraction (or within the last 2 minutes) an item counts as watched. */
export const FINISHED_FRACTION = 0.92;

export type ProgressMap = Record<string, ProgressEntry>;

export function isFinished(position: number, duration: number): boolean {
  if (!duration || duration <= 0) return false;
  return position / duration >= FINISHED_FRACTION || duration - position <= 120;
}

export function updateProgress(
  map: ProgressMap,
  contentId: string,
  positionSeconds: number,
  durationSeconds: number,
  now: Date = new Date()
): ProgressMap {
  if (!Number.isFinite(positionSeconds) || positionSeconds < 0) return map;
  const duration = Number.isFinite(durationSeconds) && durationSeconds > 0 ? durationSeconds : map[contentId]?.durationSeconds ?? 0;
  return {
    ...map,
    [contentId]: {
      contentId,
      positionSeconds: Math.floor(positionSeconds),
      durationSeconds: Math.floor(duration),
      updatedAt: now.toISOString(),
      finished: isFinished(positionSeconds, duration),
    },
  };
}

/** Where to start playback for this item (0 = from the beginning). */
export function resumePosition(map: ProgressMap, contentId: string): number {
  const p = map[contentId];
  if (!p || p.finished || p.positionSeconds < MIN_RESUME_SECONDS) return 0;
  return p.positionSeconds;
}

export function progressFraction(map: ProgressMap, contentId: string): number {
  const p = map[contentId];
  if (!p || !p.durationSeconds) return 0;
  if (p.finished) return 1;
  return Math.min(1, p.positionSeconds / p.durationSeconds);
}

export interface EpisodeRef {
  seasonNumber: number;
  episode: Episode;
}

export function findNextEpisode(series: SeriesItem, seasonNumber: number, episodeId: string): EpisodeRef | null {
  const seasons = [...series.seasons].sort((a, b) => a.seasonNumber - b.seasonNumber);
  for (let s = 0; s < seasons.length; s++) {
    const eps = seasons[s].episodes;
    if (seasons[s].seasonNumber !== seasonNumber) continue;
    const idx = eps.findIndex((e) => e.id === episodeId);
    if (idx === -1) continue;
    if (idx + 1 < eps.length) return { seasonNumber, episode: eps[idx + 1] };
    for (let n = s + 1; n < seasons.length; n++) {
      if (seasons[n].episodes.length > 0) return { seasonNumber: seasons[n].seasonNumber, episode: seasons[n].episodes[0] };
    }
    return null;
  }
  return null;
}

/**
 * The episode a "Continuar" / "Assistir" button should open for a series:
 * the most recently watched unfinished episode, otherwise the one after the
 * last finished episode, otherwise the first episode.
 */
export function episodeToResume(series: SeriesItem, map: ProgressMap): EpisodeRef | null {
  let latest: { ref: EpisodeRef; at: string; finished: boolean } | null = null;
  for (const season of series.seasons) {
    for (const episode of season.episodes) {
      const p = map[episode.id];
      if (!p) continue;
      if (!latest || p.updatedAt > latest.at) {
        latest = { ref: { seasonNumber: season.seasonNumber, episode }, at: p.updatedAt, finished: p.finished };
      }
    }
  }
  if (latest) {
    if (!latest.finished) return latest.ref;
    return findNextEpisode(series, latest.ref.seasonNumber, latest.ref.episode.id) ?? latest.ref;
  }
  const first = series.seasons.find((s) => s.episodes.length > 0);
  return first ? { seasonNumber: first.seasonNumber, episode: first.episodes[0] } : null;
}

/** History entries for the "Continuar assistindo" row: unfinished VOD and episodes, newest first. */
export function continueWatching(history: WatchHistoryItem[], map: ProgressMap, limit = 12): WatchHistoryItem[] {
  const seenSeries = new Set<string>();
  const out: WatchHistoryItem[] = [];
  const sorted = [...history].sort((a, b) => (a.timestamp < b.timestamp ? 1 : -1));
  for (const h of sorted) {
    if (h.contentType === 'channel') continue;
    if (resumePosition(map, h.contentId) === 0) continue;
    if (h.seriesId) {
      if (seenSeries.has(h.seriesId)) continue;
      seenSeries.add(h.seriesId);
    }
    out.push(h);
    if (out.length >= limit) break;
  }
  return out;
}
