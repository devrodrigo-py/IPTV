import { Channel, Episode, SeriesItem, VodItem } from '../types';

/**
 * Many provider M3U files mix live channels, movies and series episodes in
 * one list. Xtream-style URLs make the kind explicit (/movie/, /series/);
 * otherwise an "S01E02" pattern in the name marks an episode.
 */

const EPISODE_RE = /^(.*?)[\s._-]*S(\d{1,2})[\s._-]*E(\d{1,3})\b(.*)$/i;
const VIDEO_FILE_RE = /\.(mp4|mkv|avi|mov|m4v|webm)(\?|$)/i;

export interface ClassifiedM3u {
  channels: Channel[];
  vod: VodItem[];
  series: SeriesItem[];
}

function yearOf(name: string): number {
  const m = name.match(/[([\s](19\d{2}|20\d{2})[)\]\s]?/);
  return m ? parseInt(m[1], 10) : 0;
}

function cleanTitle(name: string): string {
  return name
    .replace(/\s*[([]?(19|20)\d{2}[)\]]?\s*$/, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function classifyM3u(entries: Channel[], playlistId: string): ClassifiedM3u {
  const channels: Channel[] = [];
  const vod: VodItem[] = [];
  const seriesMap = new Map<string, SeriesItem>();

  for (const e of entries) {
    const url = e.streamUrl;
    const isSeriesUrl = /\/series\//i.test(url);
    const isMovieUrl = /\/movie\//i.test(url);
    const epMatch = e.name.match(EPISODE_RE);

    if ((isSeriesUrl || (epMatch && VIDEO_FILE_RE.test(url))) && epMatch) {
      const showTitle = epMatch[1].trim() || e.name;
      const seasonNumber = parseInt(epMatch[2], 10);
      const episodeNumber = parseInt(epMatch[3], 10);
      const key = showTitle.toLowerCase();
      let show = seriesMap.get(key);
      if (!show) {
        show = {
          id: `ser_${playlistId}_${seriesMap.size + 1}`,
          playlistId,
          title: showTitle,
          posterUrl: e.logoUrl || '',
          overview: '',
          rating: 0,
          category: e.groupTitle || 'Séries',
          seasons: [],
          seasonsLoaded: true,
        };
        seriesMap.set(key, show);
      }
      let season = show.seasons.find((s) => s.seasonNumber === seasonNumber);
      if (!season) {
        season = { seasonNumber, title: `Temporada ${seasonNumber}`, episodes: [] };
        show.seasons.push(season);
      }
      const episode: Episode = {
        id: `ep_${show.id}_${seasonNumber}_${episodeNumber}_${season.episodes.length}`,
        episodeNumber,
        title: epMatch[4].replace(/^[\s._-]+/, '').trim() || `Episódio ${episodeNumber}`,
        overview: '',
        streamUrl: url,
        durationMinutes: 0,
        stillUrl: e.logoUrl,
      };
      season.episodes.push(episode);
      continue;
    }

    if (isMovieUrl || VIDEO_FILE_RE.test(url)) {
      vod.push({
        id: `vod_${playlistId}_${vod.length + 1}`,
        playlistId,
        title: cleanTitle(e.name),
        posterUrl: e.logoUrl || '',
        description: '',
        year: yearOf(e.name),
        rating: 0,
        durationMinutes: 0,
        category: e.groupTitle || 'Filmes',
        streamUrl: url,
      });
      continue;
    }

    channels.push(e);
  }

  const series = Array.from(seriesMap.values());
  for (const s of series) {
    s.seasons.sort((a, b) => a.seasonNumber - b.seasonNumber);
    for (const season of s.seasons) season.episodes.sort((a, b) => a.episodeNumber - b.episodeNumber);
  }
  return { channels, vod, series };
}
