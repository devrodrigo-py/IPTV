import { AppSettings, Channel, EpgProgram, Playlist, UserProfile, VodItem, SeriesItem, WatchHistoryItem, WatchStats } from '../types';
import { DEFAULT_PROFILES, DEFAULT_SETTINGS, EMPTY_STATS } from './sampleData';
import { dbDelete, dbGet, dbSet } from './db';
import type { ProgressMap } from './progress';

/**
 * Small, frequently read data stays in localStorage (synchronous at startup).
 * Large catalog data lives in IndexedDB (see db.ts): localStorage caps at about
 * 5 MB, which one real provider list already exceeds.
 */

const LS = {
  PROFILES: 'nebula_profiles',
  ACTIVE_PROFILE: 'nebula_active_profile',
  PLAYLISTS: 'nebula_playlists',
  FAVORITES: 'nebula_favorites',
  HISTORY: 'nebula_history',
  SETTINGS: 'nebula_settings',
  STATS: 'nebula_stats',
} as const;

/** Keys in IndexedDB. */
export const DB_KEYS = {
  CHANNELS: 'channels',
  VOD: 'vod',
  SERIES: 'series',
  EPG: 'epg',
  PROGRESS: 'progress',
} as const;

/** Pre-IndexedDB versions stored these in localStorage. */
const LEGACY_LS = {
  CHANNELS: 'nebula_channels',
  VOD: 'nebula_vod',
  SERIES: 'nebula_series',
  EPG: 'nebula_epg',
};

function readLs<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (raw) return JSON.parse(raw) as T;
  } catch (e) {
    console.error(`Falha ao ler ${key}:`, e);
  }
  return fallback;
}

function writeLs(key: string, value: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    console.error(`Falha ao salvar ${key}:`, e);
  }
}

export const loadProfiles = (): UserProfile[] => {
  const p = readLs<UserProfile[]>(LS.PROFILES, []);
  return p.length ? p : DEFAULT_PROFILES;
};
export const saveProfiles = (v: UserProfile[]) => writeLs(LS.PROFILES, v);
export const loadActiveProfileId = (): string => localStorage.getItem(LS.ACTIVE_PROFILE) || DEFAULT_PROFILES[0].id;
export const saveActiveProfileId = (id: string) => localStorage.setItem(LS.ACTIVE_PROFILE, id);
export const loadPlaylists = (): Playlist[] => readLs<Playlist[]>(LS.PLAYLISTS, []);
export const savePlaylists = (v: Playlist[]) => writeLs(LS.PLAYLISTS, v);
export const loadFavorites = (): string[] => readLs<string[]>(LS.FAVORITES, []);
export const saveFavorites = (v: string[]) => writeLs(LS.FAVORITES, v);
export const loadHistory = (): WatchHistoryItem[] => readLs<WatchHistoryItem[]>(LS.HISTORY, []);
export const saveHistory = (v: WatchHistoryItem[]) => writeLs(LS.HISTORY, v);
export const loadSettings = (): AppSettings => ({ ...DEFAULT_SETTINGS, ...readLs<Partial<AppSettings>>(LS.SETTINGS, {}) });
export const saveSettings = (v: AppSettings) => writeLs(LS.SETTINGS, v);
export const loadStats = (): WatchStats => ({ ...EMPTY_STATS, ...readLs<Partial<WatchStats>>(LS.STATS, {}) });
export const saveStats = (v: WatchStats) => writeLs(LS.STATS, v);

export interface CatalogData {
  channels: Channel[];
  vod: VodItem[];
  series: SeriesItem[];
  epg: EpgProgram[];
  progress: ProgressMap;
}

/**
 * Loads catalog data from IndexedDB. On the first run after upgrading, data
 * left in localStorage by older versions is moved over and removed there.
 */
export async function loadCatalog(): Promise<CatalogData> {
  const [channels, vod, series, epg, progress] = await Promise.all([
    dbGet<Channel[]>(DB_KEYS.CHANNELS),
    dbGet<VodItem[]>(DB_KEYS.VOD),
    dbGet<SeriesItem[]>(DB_KEYS.SERIES),
    dbGet<EpgProgram[]>(DB_KEYS.EPG),
    dbGet<ProgressMap>(DB_KEYS.PROGRESS),
  ]);

  const data: CatalogData = {
    channels: channels ?? readLs<Channel[]>(LEGACY_LS.CHANNELS, []),
    vod: vod ?? readLs<VodItem[]>(LEGACY_LS.VOD, []),
    series: series ?? readLs<SeriesItem[]>(LEGACY_LS.SERIES, []),
    epg: epg ?? readLs<EpgProgram[]>(LEGACY_LS.EPG, []),
    progress: progress ?? {},
  };

  if (!channels && localStorage.getItem(LEGACY_LS.CHANNELS)) {
    await Promise.all([
      dbSet(DB_KEYS.CHANNELS, data.channels),
      dbSet(DB_KEYS.VOD, data.vod),
      dbSet(DB_KEYS.SERIES, data.series),
      dbSet(DB_KEYS.EPG, data.epg),
    ]);
    Object.values(LEGACY_LS).forEach((k) => localStorage.removeItem(k));
  }
  return data;
}

export async function clearEpgCache(): Promise<void> {
  await dbDelete(DB_KEYS.EPG);
}

/**
 * Backup of user data (profiles, lists, favourites, history, progress).
 * Catalogs are not included: they are downloaded again from the lists.
 * Note: the file contains list passwords so it can restore Xtream logins.
 */
export async function exportNebulaData(): Promise<string> {
  const progress = (await dbGet<ProgressMap>(DB_KEYS.PROGRESS).catch(() => undefined)) ?? {};
  return JSON.stringify(
    {
      version: '3.0.0',
      exportedAt: new Date().toISOString(),
      profiles: loadProfiles(),
      playlists: loadPlaylists(),
      favorites: loadFavorites(),
      history: loadHistory(),
      settings: loadSettings(),
      stats: loadStats(),
      progress,
    },
    null,
    2
  );
}

export async function importNebulaData(jsonString: string): Promise<boolean> {
  try {
    const parsed = JSON.parse(jsonString);
    if (!parsed || typeof parsed !== 'object') return false;

    if (Array.isArray(parsed.profiles)) {
      const valid = parsed.profiles.filter((p: UserProfile) => p && typeof p.id === 'string' && typeof p.name === 'string');
      if (valid.length > 0) saveProfiles(valid);
    }
    if (Array.isArray(parsed.playlists)) {
      savePlaylists(parsed.playlists.filter((pl: Playlist) => pl && typeof pl.id === 'string' && typeof pl.name === 'string'));
    }
    if (Array.isArray(parsed.favorites)) saveFavorites(parsed.favorites.filter((f: unknown) => typeof f === 'string'));
    if (Array.isArray(parsed.history)) {
      saveHistory(parsed.history.filter((h: WatchHistoryItem) => h && typeof h.id === 'string' && typeof h.streamUrl === 'string'));
    }
    if (parsed.settings && typeof parsed.settings === 'object') saveSettings({ ...loadSettings(), ...parsed.settings });
    if (parsed.stats && typeof parsed.stats === 'object') saveStats({ ...loadStats(), ...parsed.stats });
    if (parsed.progress && typeof parsed.progress === 'object') await dbSet(DB_KEYS.PROGRESS, parsed.progress);
    // Older backups carried channels; keep them so the app is not empty until a refresh.
    if (Array.isArray(parsed.channels)) {
      await dbSet(DB_KEYS.CHANNELS, parsed.channels.filter((c: Channel) => c && typeof c.id === 'string' && typeof c.streamUrl === 'string'));
    }
    return true;
  } catch (e) {
    console.error('Erro ao importar backup:', e);
    return false;
  }
}
