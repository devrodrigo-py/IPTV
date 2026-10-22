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
  channelCount: number;
  lastSync: string;
  isActive: boolean;
  autoSyncMinutes?: number;
}

export interface VodItem {
  id: string;
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
  title: string;
  posterUrl: string;
  backdropUrl?: string;
  overview: string;
  rating: number;
  category: string;
  seasons: Season[];
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
}
