import { describe, expect, it } from 'vitest';
import { continueWatching, episodeToResume, findNextEpisode, isFinished, resumePosition, updateProgress } from '../progress';
import { SeriesItem, WatchHistoryItem } from '../../types';

const ep = (id: string, n: number) => ({ id, episodeNumber: n, title: id, overview: '', streamUrl: id, durationMinutes: 40 });
const series: SeriesItem = {
  id: 's1', title: 'S', posterUrl: '', overview: '', rating: 0, category: 'D',
  seasons: [
    { seasonNumber: 1, title: 'T1', episodes: [ep('e1', 1), ep('e2', 2)] },
    { seasonNumber: 2, title: 'T2', episodes: [ep('e3', 1)] },
  ],
};

describe('progress', () => {
  it('marks near-end as finished', () => {
    expect(isFinished(5600, 6000)).toBe(true);
    expect(isFinished(100, 6000)).toBe(false);
    expect(isFinished(100, 0)).toBe(false);
  });

  it('resumes only meaningful positions', () => {
    let m = updateProgress({}, 'a', 10, 1000);
    expect(resumePosition(m, 'a')).toBe(0);
    m = updateProgress(m, 'a', 400.7, 1000);
    expect(resumePosition(m, 'a')).toBe(400);
    m = updateProgress(m, 'a', 990, 1000);
    expect(resumePosition(m, 'a')).toBe(0);
  });

  it('keeps the known duration when the player reports none (live-like streams)', () => {
    let m = updateProgress({}, 'a', 100, 1000);
    m = updateProgress(m, 'a', 200, NaN);
    expect(m.a.durationSeconds).toBe(1000);
  });

  it('ignores invalid positions', () => {
    const m = updateProgress({}, 'a', NaN, 100);
    expect(m).toEqual({});
  });

  it('finds next episode across seasons', () => {
    expect(findNextEpisode(series, 1, 'e1')?.episode.id).toBe('e2');
    expect(findNextEpisode(series, 1, 'e2')).toMatchObject({ seasonNumber: 2, episode: { id: 'e3' } });
    expect(findNextEpisode(series, 2, 'e3')).toBeNull();
  });

  it('chooses the episode to resume', () => {
    expect(episodeToResume(series, {})?.episode.id).toBe('e1');
    const t = (s: string) => new Date(s);
    let m = updateProgress({}, 'e1', 2400, 2400, t('2026-01-01'));
    expect(episodeToResume(series, m)?.episode.id).toBe('e2');
    m = updateProgress(m, 'e2', 300, 2400, t('2026-01-02'));
    expect(episodeToResume(series, m)?.episode.id).toBe('e2');
  });

  it('builds the continue-watching row: unfinished, newest first, one per series', () => {
    const h = (contentId: string, ts: string, extra: Partial<WatchHistoryItem> = {}): WatchHistoryItem => ({
      id: contentId, contentId, contentType: 'vod', title: contentId, streamUrl: '', timestamp: ts, positionSeconds: 0, ...extra,
    });
    let m = updateProgress({}, 'm1', 500, 6000);
    m = updateProgress(m, 'm2', 5990, 6000);
    m = updateProgress(m, 'e1', 300, 2400);
    m = updateProgress(m, 'e2', 300, 2400);
    const rows = continueWatching(
      [
        h('m1', '2026-01-01'),
        h('m2', '2026-01-03'),
        h('e1', '2026-01-02', { contentType: 'series', seriesId: 's1' }),
        h('e2', '2026-01-04', { contentType: 'series', seriesId: 's1' }),
        h('ch', '2026-01-05', { contentType: 'channel' }),
      ],
      m
    );
    expect(rows.map((r) => r.contentId)).toEqual(['e2', 'm1']);
  });
});
