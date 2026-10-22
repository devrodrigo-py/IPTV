import { AppSettings, Channel, EpgProgram, Playlist, UserProfile, VodItem, SeriesItem, WatchHistoryItem, WatchStats } from '../types';
import { DEFAULT_PROFILES, DEFAULT_SETTINGS, INITIAL_CHANNELS, INITIAL_PLAYLISTS, INITIAL_SERIES, INITIAL_STATS, INITIAL_VOD, generateSampleEpg } from './sampleData';

const STORAGE_KEYS = {
  PROFILES: 'nebula_profiles',
  ACTIVE_PROFILE: 'nebula_active_profile',
  PLAYLISTS: 'nebula_playlists',
  CHANNELS: 'nebula_channels',
  FAVORITES: 'nebula_favorites',
  HISTORY: 'nebula_history',
  EPG: 'nebula_epg',
  SETTINGS: 'nebula_settings',
  STATS: 'nebula_stats',
  VOD: 'nebula_vod',
  SERIES: 'nebula_series',
};

export function loadProfiles(): UserProfile[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.PROFILES);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load profiles:', e);
  }
  return DEFAULT_PROFILES;
}

export function saveProfiles(profiles: UserProfile[]): void {
  localStorage.setItem(STORAGE_KEYS.PROFILES, JSON.stringify(profiles));
}

export function loadActiveProfileId(): string {
  return localStorage.getItem(STORAGE_KEYS.ACTIVE_PROFILE) || DEFAULT_PROFILES[0].id;
}

export function saveActiveProfileId(id: string): void {
  localStorage.setItem(STORAGE_KEYS.ACTIVE_PROFILE, id);
}

export function loadPlaylists(): Playlist[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.PLAYLISTS);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load playlists:', e);
  }
  return INITIAL_PLAYLISTS;
}

export function savePlaylists(playlists: Playlist[]): void {
  localStorage.setItem(STORAGE_KEYS.PLAYLISTS, JSON.stringify(playlists));
}

export function loadChannels(): Channel[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.CHANNELS);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load channels:', e);
  }
  return INITIAL_CHANNELS;
}

export function saveChannels(channels: Channel[]): void {
  localStorage.setItem(STORAGE_KEYS.CHANNELS, JSON.stringify(channels));
}

export function loadFavorites(): string[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.FAVORITES);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load favorites:', e);
  }
  // Default favorites from initial channels
  return INITIAL_CHANNELS.filter(c => c.isFavorite).map(c => c.id);
}

export function saveFavorites(favIds: string[]): void {
  localStorage.setItem(STORAGE_KEYS.FAVORITES, JSON.stringify(favIds));
}

export function loadHistory(): WatchHistoryItem[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.HISTORY);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load history:', e);
  }
  return [
    {
      id: 'hist_1',
      contentId: 'ch_1',
      contentType: 'channel',
      title: 'NASA TV HD (Ciência & Espaço)',
      subtitle: 'ISS Live Views from Orbit',
      posterUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/e5/NASA_logo.svg',
      streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
      timestamp: new Date(Date.now() - 1000 * 60 * 45).toISOString(),
      positionSeconds: 1800,
    },
    {
      id: 'hist_2',
      contentId: 'vod_1',
      contentType: 'vod',
      title: 'Tears of Steel: A Resistência Cyber',
      subtitle: 'Ficção Científica • 124 min',
      posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&auto=format&fit=crop&q=80',
      streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
      timestamp: new Date(Date.now() - 1000 * 60 * 180).toISOString(),
      positionSeconds: 2450,
      durationSeconds: 7440,
    },
  ];
}

export function saveHistory(history: WatchHistoryItem[]): void {
  localStorage.setItem(STORAGE_KEYS.HISTORY, JSON.stringify(history));
}

export function loadEpg(): EpgProgram[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.EPG);
    if (raw) {
      const parsed: EpgProgram[] = JSON.parse(raw);
      if (parsed.length > 0) return parsed;
    }
  } catch (e) {
    console.error('Failed to load EPG:', e);
  }
  return generateSampleEpg();
}

export function saveEpg(epg: EpgProgram[]): void {
  localStorage.setItem(STORAGE_KEYS.EPG, JSON.stringify(epg));
}

export function loadSettings(): AppSettings {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.SETTINGS);
    if (raw) return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
  } catch (e) {
    console.error('Failed to load settings:', e);
  }
  return DEFAULT_SETTINGS;
}

export function saveSettings(settings: AppSettings): void {
  localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
}

export function loadStats(): WatchStats {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.STATS);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load stats:', e);
  }
  return INITIAL_STATS;
}

export function saveStats(stats: WatchStats): void {
  localStorage.setItem(STORAGE_KEYS.STATS, JSON.stringify(stats));
}

export function loadVod(): VodItem[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.VOD);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load VOD:', e);
  }
  return INITIAL_VOD;
}

export function saveVod(vod: VodItem[]): void {
  localStorage.setItem(STORAGE_KEYS.VOD, JSON.stringify(vod));
}

export function loadSeries(): SeriesItem[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.SERIES);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error('Failed to load series:', e);
  }
  return INITIAL_SERIES;
}

export function saveSeries(series: SeriesItem[]): void {
  localStorage.setItem(STORAGE_KEYS.SERIES, JSON.stringify(series));
}

export function exportNebulaData(): string {
  const data = {
    version: '2.1.0',
    exportedAt: new Date().toISOString(),
    profiles: loadProfiles(),
    playlists: loadPlaylists(),
    channels: loadChannels(),
    favorites: loadFavorites(),
    history: loadHistory(),
    settings: loadSettings(),
    stats: loadStats(),
  };
  return JSON.stringify(data, null, 2);
}

export function importNebulaData(jsonString: string): boolean {
  try {
    const parsed = JSON.parse(jsonString);
    if (parsed.profiles) saveProfiles(parsed.profiles);
    if (parsed.playlists) savePlaylists(parsed.playlists);
    if (parsed.channels) saveChannels(parsed.channels);
    if (parsed.favorites) saveFavorites(parsed.favorites);
    if (parsed.history) saveHistory(parsed.history);
    if (parsed.settings) saveSettings(parsed.settings);
    if (parsed.stats) saveStats(parsed.stats);
    return true;
  } catch (e) {
    console.error('Error importing backup:', e);
    return false;
  }
}
