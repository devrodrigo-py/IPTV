export type PlaylistType = 'm3u' | 'xtream';

export interface Channel {
  id: string;
  sourceId?: string;
  playlistId: string;
  name: string;
  streamUrl: string;
  logoUrl?: string;
  groupTitle?: string;
  tvgId?: string;
  tvgName?: string;
  resolution?: '4K' | 'FHD' | 'HD' | 'SD';
  isFavorite?: boolean;
}

export interface EpgProgram {
  id: string;
  channelId: string;
  title: string;
  description?: string;
  startUtc: string; // ISO string
  endUtc: string;   // ISO string
  category?: string;
  iconUrl?: string;
}

export interface Playlist {
  id: string;
  name: string;
  type: PlaylistType;
  url?: string;
  username?: string;
  password?: string;
  /** XMLTV guide URL (from M3U header url-tvg or Xtream xmltv.php). */
  epgUrl?: string;
  channelCount: number;
  vodCount?: number;
  seriesCount?: number;
  lastSync: string;
  isActive: boolean;
  autoSyncMinutes?: number;
}

export interface VodItem {
  id: string;
  playlistId?: string;
  /** Provider id (Xtream stream_id) used for get_vod_info. */
  sourceId?: string;
  tmdbId?: string;
  title: string;
  posterUrl: string;
  backdropUrl?: string;
  description: string;
  year: number;
  rating: number; // 0-10
  durationMinutes: number;
  category: string;
  streamUrl: string;
  director?: string;
  cast?: string[];
  addedAt?: number; // epoch seconds, used for "Adicionados recentemente"
}

export interface Episode {
  id: string;
  episodeNumber: number;
  title: string;
  overview: string;
  streamUrl: string;
  durationMinutes: number;
  stillUrl?: string;
}

export interface Season {
  seasonNumber: number;
  title: string;
  episodes: Episode[];
}

export interface SeriesItem {
  id: string;
  playlistId?: string;
  /** Provider id (Xtream series_id) used for lazy get_series_info. */
  sourceId?: string;
  tmdbId?: string;
  year?: number;
  addedAt?: number;
  title: string;
  posterUrl: string;
  backdropUrl?: string;
  overview: string;
  rating: number;
  category: string;
  seasons: Season[];
  /** False when seasons must still be fetched from the provider. */
  seasonsLoaded?: boolean;
}

export interface WatchHistoryItem {
  id: string;
  contentId: string;
  contentType: 'channel' | 'vod' | 'series';
  title: string;
  subtitle?: string;
  posterUrl?: string;
  streamUrl: string;
  timestamp: string; // ISO
  positionSeconds: number;
  durationSeconds?: number;
  /** For episodes: the series id, so "Continuar" can reopen the series. */
  seriesId?: string;
  seasonNumber?: number;
  episodeNumber?: number;
}

/** Playback progress for on-demand content (movies and episodes). */
export interface ProgressEntry {
  contentId: string;
  positionSeconds: number;
  durationSeconds: number;
  updatedAt: string; // ISO
  finished: boolean;
}

export interface UserProfile {
  id: string;
  name: string;
  avatar: string;
  isKids: boolean;
  pin?: string; // Optional 4-digit PIN lock
  createdAt: string;
}

export interface WatchStats {
  totalMinutesWatched: number;
  channelPlayCounts: Record<string, number>;
  genreCounts: Record<string, number>;
  daysActive: number;
  lastWatchedDate?: string;
}

export interface AppSettings {
  themeAccent: 'violet' | 'teal' | 'coral';
  bufferMode: 'low' | 'balanced' | 'high';
  tvMode: boolean; // 10-foot UI
  parentalControlEnabled: boolean;
  masterPin: string;
  streamAutoplay: boolean;
  /** Prefix used by the browser build to reach servers without CORS, e.g. https://proxy.example/?url= */
  corsProxyUrl: string;
  /** Optional TMDB v3 API key or v4 read token for posters, backdrops and synopses. */
  tmdbApiKey: string;
  /** Lighter visuals and fewer simultaneous decoders for low-end TV sticks. */
  liteMode: 'auto' | 'on' | 'off';
  /** Android: play through the native Media3 player instead of the WebView. */
  useNativePlayer: boolean;
  /** Start the next episode automatically when one ends. */
  autoplayNextEpisode: boolean;
}
