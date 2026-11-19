import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import {
  AppSettings,
  Channel,
  Episode,
  EpgProgram,
  Playlist,
  PlaylistType,
  UserProfile,
  VodItem,
  SeriesItem,
  WatchHistoryItem,
  WatchStats,
} from '../types';
import {
  DB_KEYS,
  loadProfiles,
  saveProfiles,
  loadActiveProfileId,
  saveActiveProfileId,
  loadPlaylists,
  savePlaylists,
  loadFavorites,
  saveFavorites,
  loadHistory,
  saveHistory,
  loadSettings,
  saveSettings,
  loadStats,
  saveStats,
  loadCatalog,
} from '../data/storage';
import { createDebouncedWriter } from '../data/db';
import { parseM3uAsync, parseXmltvAsync } from '../data/parseService';
import {
  ProgressMap,
  continueWatching,
  episodeToResume,
  findNextEpisode,
  progressFraction,
  resumePosition,
  updateProgress,
} from '../data/progress';
import { EpgIndex, buildEpgIndex, currentProgram, keepKnownChannels, programsFor } from '../data/epg';
import { XtreamCredentials, fetchCatalog, fetchSeriesInfo, fetchVodInfo } from '../data/xtream';
import { lookupTmdb } from '../data/tmdb';
import {
  DEMO_PLAYLIST_ID,
  INITIAL_CHANNELS,
  INITIAL_PLAYLISTS,
  INITIAL_SERIES,
  INITIAL_STATS,
  INITIAL_VOD,
  generateSampleEpg,
} from '../data/sampleData';
import { httpGetMaybeGzipText, httpGetText, setCorsProxy } from '../platform/http';
import { DeviceProfile, getDeviceProfile, isNativeApp } from '../platform/platform';
import { NativeQueueItem, canUseNativePlayer, playNative } from '../platform/nativePlayer';

export type TabType =
  | 'home'
  | 'channels'
  | 'vod'
  | 'series'
  | 'favorites'
  | 'history'
  | 'playlists'
  | 'epg'
  | 'multiview'
  | 'stats'
  | 'settings'
  | 'search'
  | 'mylist';

export interface ActiveStream {
  id: string;
  title: string;
  subtitle?: string;
  streamUrl: string;
  logoUrl?: string;
  isLive: boolean;
  channel?: Channel;
  vod?: VodItem;
  series?: SeriesItem;
  episode?: { id: string; title: string; episodeNumber: number; seasonNumber: number; streamUrl: string };
  /** Where on-demand playback should start (seconds). */
  startPositionSeconds?: number;
}

export interface SyncStatus {
  playlistId: string;
  step: string;
}

export interface PlaylistResult {
  success: boolean;
  channelCount: number;
  vodCount?: number;
  seriesCount?: number;
  message?: string;
}

const MASKED_PASSWORD = '••••••••';
const KIDS_KEYWORDS = ['infantil', 'desenho', 'kids', 'criança', 'crianca', 'animação', 'animacao', 'família', 'familia', 'cartoon', 'disney'];

interface AppContextValue {
  activeTab: TabType;
  setActiveTab: (tab: TabType) => void;

  /** False until catalog data has been read from IndexedDB. */
  isHydrated: boolean;
  deviceProfile: DeviceProfile;
  /** Lighter visuals for low-end sticks (Settings > Modo leve). */
  isLite: boolean;

  profiles: UserProfile[];
  activeProfile: UserProfile | null;
  isGateLocked: boolean;
  selectProfile: (profile: UserProfile, pinAttempt?: string) => boolean;
  lockToProfileGate: () => void;
  updateProfile: (profile: UserProfile) => void;
  createProfile: (profileData: Omit<UserProfile, 'id' | 'createdAt'>) => void;
  deleteProfile: (id: string) => void;

  playlists: Playlist[];
  syncStatus: SyncStatus | null;
  addPlaylist: (
    name: string,
    type: PlaylistType,
    source: { url?: string; content?: string; username?: string; password?: string; epgUrl?: string }
  ) => Promise<PlaylistResult>;
  deletePlaylist: (id: string) => void;
  togglePlaylist: (id: string) => void;
  refreshPlaylist: (id: string) => Promise<PlaylistResult>;
  loadDemoContent: () => void;

  channels: Channel[];
  filteredChannels: Channel[];
  categories: string[];
  favorites: string[];
  /** "Minha lista": movie and series ids saved by the active profile. */
  myList: string[];
  toggleMyList: (contentId: string) => void;
  isInMyList: (contentId: string) => boolean;
  toggleFavorite: (channelId: string) => void;
  isFavorite: (channelId: string) => boolean;

  currentStream: ActiveStream | null;
  isPlayerOpen: boolean;
  playChannel: (channel: Channel, queue?: Channel[]) => void;
  playVod: (vod: VodItem, fromStart?: boolean) => void;
  playEpisode: (series: SeriesItem, seasonNumber: number, episode: Episode, fromStart?: boolean) => void;
  playDirectStream: (stream: ActiveStream) => void;
  /** Plays the episode after the one currently open, if any. Returns false at the end of a series. */
  playNextEpisode: () => boolean;
  getNextEpisodeTitle: () => string | null;
  closePlayer: () => void;

  history: WatchHistoryItem[];
  addToHistory: (item: Omit<WatchHistoryItem, 'id' | 'timestamp'>) => void;
  clearHistory: () => void;
  resumeHistoryItem: (item: WatchHistoryItem) => void;

  saveProgress: (contentId: string, positionSeconds: number, durationSeconds: number) => void;
  getResumeSeconds: (contentId: string) => number;
  getProgressFraction: (contentId: string) => number;
  progressMap: ProgressMap;
  continueWatchingItems: WatchHistoryItem[];

  epgPrograms: EpgProgram[];
  getChannelCurrentProgram: (channelId: string) => EpgProgram | undefined;
  getChannelPrograms: (channelId: string) => EpgProgram[];
  importXmltv: (content: string) => Promise<{ success: boolean; programCount: number }>;
  importEpgFromUrl: (url: string) => Promise<{ success: boolean; programCount: number; message?: string }>;

  vodItems: VodItem[];
  seriesItems: SeriesItem[];
  selectedVodModal: VodItem | null;
  setSelectedVodModal: (vod: VodItem | null) => void;
  selectedSeriesModal: SeriesItem | null;
  setSelectedSeriesModal: (series: SeriesItem | null) => void;
  /** Fetches seasons/episodes (Xtream) and TMDB artwork for a series on demand. */
  loadSeriesDetails: (series: SeriesItem) => Promise<SeriesItem>;
  loadVodDetails: (vod: VodItem) => Promise<VodItem>;
  /** Fills in missing artwork for a title from TMDB (no-op without an API key). */
  enrichArtwork: (kind: 'vod' | 'series', id: string) => void;

  stats: WatchStats;
  trackWatchTime: (channelName: string, genre: string, minutes?: number) => void;
  isWrappedOpen: boolean;
  setIsWrappedOpen: (open: boolean) => void;

  settings: AppSettings;
  updateSettings: (newSettings: Partial<AppSettings>) => void;

  searchQuery: string;
  setSearchQuery: (q: string) => void;

  tvMode: boolean;
  toggleTvMode: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

function credentialsFor(pl: Playlist | undefined): XtreamCredentials | null {
  if (!pl || pl.type !== 'xtream' || !pl.url || !pl.username || !pl.password || pl.password === MASKED_PASSWORD) return null;
  return { baseUrl: pl.url, username: pl.username, password: pl.password };
}

function isKidFriendly(category: string | undefined, name = ''): boolean {
  const text = `${category || ''} ${name}`.toLowerCase();
  return KIDS_KEYWORDS.some((k) => text.includes(k));
}

function errorMessage(e: unknown): string {
  return (e as Error)?.message || 'Erro desconhecido';
}

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [searchQuery, setSearchQuery] = useState('');
  const deviceProfile = useMemo(() => getDeviceProfile(), []);

  // Profiles
  const [profiles, setProfiles] = useState<UserProfile[]>(loadProfiles);
  const [activeProfile, setActiveProfile] = useState<UserProfile | null>(() => {
    const loaded = loadProfiles();
    const activeId = loadActiveProfileId();
    return loaded.find((p) => p.id === activeId) || loaded[0] || null;
  });
  // Like streaming apps: ask who is watching on launch when there is more than one profile.
  const [isGateLocked, setIsGateLocked] = useState(() => loadProfiles().length > 1);

  // Small data (localStorage)
  const [playlists, setPlaylists] = useState<Playlist[]>(loadPlaylists);
  const [favorites, setFavorites] = useState<string[]>(loadFavorites);
  const [history, setHistory] = useState<WatchHistoryItem[]>(loadHistory);
  const [stats, setStats] = useState<WatchStats>(loadStats);
  const [settings, setSettings] = useState<AppSettings>(loadSettings);

  // Large data (IndexedDB), loaded asynchronously
  const [isHydrated, setIsHydrated] = useState(false);
  const [channels, setChannels] = useState<Channel[]>([]);
  const [epgPrograms, setEpgPrograms] = useState<EpgProgram[]>([]);
  const [vodAll, setVodAll] = useState<VodItem[]>([]);
  const [seriesAll, setSeriesAll] = useState<SeriesItem[]>([]);
  const [progress, setProgress] = useState<ProgressMap>({});
  const [syncStatus, setSyncStatus] = useState<SyncStatus | null>(null);

  // Player state
  const [currentStream, setCurrentStream] = useState<ActiveStream | null>(null);
  const [isPlayerOpen, setIsPlayerOpen] = useState(false);

  // Modals
  const [selectedVodModal, setSelectedVodModal] = useState<VodItem | null>(null);
  const [selectedSeriesModal, setSelectedSeriesModal] = useState<SeriesItem | null>(null);
  const [isWrappedOpen, setIsWrappedOpen] = useState(false);

  const writer = useRef(createDebouncedWriter(600)).current;
  const playlistsRef = useRef(playlists);
  playlistsRef.current = playlists;
  const channelsRef = useRef(channels);
  channelsRef.current = channels;

  // ---------------------------------------------------------------- hydration
  useEffect(() => {
    let cancelled = false;
    loadCatalog()
      .then((data) => {
        if (cancelled) return;
        setChannels(data.channels);
        setVodAll(data.vod);
        setSeriesAll(data.series);
        setEpgPrograms(data.epg);
        setProgress(data.progress);
      })
      .catch((e) => console.error('Falha ao carregar catálogo local:', e))
      .finally(() => {
        if (!cancelled) setIsHydrated(true);
      });
    const flush = () => void writer.flushAll();
    window.addEventListener('pagehide', flush);
    document.addEventListener('visibilitychange', flush);
    return () => {
      cancelled = true;
      window.removeEventListener('pagehide', flush);
      document.removeEventListener('visibilitychange', flush);
    };
  }, [writer]);

  // ---------------------------------------------------------------- persistence
  useEffect(() => saveProfiles(profiles), [profiles]);
  useEffect(() => {
    if (activeProfile) saveActiveProfileId(activeProfile.id);
  }, [activeProfile]);
  useEffect(() => savePlaylists(playlists), [playlists]);
  useEffect(() => saveFavorites(favorites), [favorites]);
  useEffect(() => saveHistory(history), [history]);
  useEffect(() => saveStats(stats), [stats]);
  useEffect(() => {
    saveSettings(settings);
    setCorsProxy(settings.corsProxyUrl);
  }, [settings]);

  // Never write before hydration: that would overwrite stored data with empty arrays.
  useEffect(() => {
    if (isHydrated) writer.write(DB_KEYS.CHANNELS, channels);
  }, [channels, isHydrated, writer]);
  useEffect(() => {
    if (isHydrated) writer.write(DB_KEYS.VOD, vodAll);
  }, [vodAll, isHydrated, writer]);
  useEffect(() => {
    if (isHydrated) writer.write(DB_KEYS.SERIES, seriesAll);
  }, [seriesAll, isHydrated, writer]);
  useEffect(() => {
    if (isHydrated) writer.write(DB_KEYS.EPG, epgPrograms);
  }, [epgPrograms, isHydrated, writer]);
  useEffect(() => {
    if (isHydrated) writer.write(DB_KEYS.PROGRESS, progress);
  }, [progress, isHydrated, writer]);

  // ---------------------------------------------------------------- profiles
  const selectProfile = (profile: UserProfile, pinAttempt?: string): boolean => {
    if (profile.pin && profile.pin !== pinAttempt) return false;
    setActiveProfile(profile);
    setIsGateLocked(false);
    return true;
  };
  const lockToProfileGate = () => setIsGateLocked(true);
  const updateProfile = (updated: UserProfile) => {
    setProfiles((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
    if (activeProfile?.id === updated.id) setActiveProfile(updated);
  };
  const createProfile = (data: Omit<UserProfile, 'id' | 'createdAt'>) => {
    setProfiles((prev) => [...prev, { ...data, id: `prof_${Date.now()}`, createdAt: new Date().toISOString() }]);
  };
  const deleteProfile = (id: string) => {
    if (profiles.length <= 1) return;
    setProfiles((prev) => prev.filter((p) => p.id !== id));
    if (activeProfile?.id === id) setActiveProfile(profiles.find((p) => p.id !== id) || null);
  };

  // ---------------------------------------------------------------- EPG
  const epgIndex: EpgIndex = useMemo(() => buildEpgIndex(epgPrograms), [epgPrograms]);
  const channelById = useMemo(() => new Map(channels.map((c) => [c.id, c])), [channels]);

  /** Replaces guide data for the channels present in `programs`, keeps the rest. */
  const mergeEpg = useCallback((programs: EpgProgram[]) => {
    const keys = new Set(programs.map((p) => p.channelId));
    setEpgPrograms((prev) => [...prev.filter((p) => !keys.has(p.channelId)), ...programs]);
  }, []);

  const importXmltv = async (content: string) => {
    const programs = await parseXmltvAsync(content);
    if (programs.length === 0) return { success: false, programCount: 0 };
    mergeEpg(programs);
    return { success: true, programCount: programs.length };
  };

  const importEpgFromUrl = useCallback(
    async (url: string, knownChannels?: Channel[]) => {
      try {
        const text = await httpGetMaybeGzipText(url, { timeoutMs: 180_000 });
        let programs = await parseXmltvAsync(text);
        const pool = knownChannels ?? channelsRef.current;
        if (pool.length) programs = keepKnownChannels(programs, pool);
        if (programs.length === 0) return { success: false, programCount: 0, message: 'Nenhum programa do guia corresponde aos seus canais.' };
        mergeEpg(programs);
        return { success: true, programCount: programs.length };
      } catch (e) {
        return { success: false, programCount: 0, message: errorMessage(e) };
      }
    },
    [mergeEpg]
  );
  const getChannelCurrentProgram = (channelId: string) => {
    const ch = channelById.get(channelId);
    return currentProgram(ch ? programsFor(epgIndex, ch) : epgIndex.get(channelId) ?? []);
  };
  const getChannelPrograms = (channelId: string) => {
    const ch = channelById.get(channelId);
    return ch ? programsFor(epgIndex, ch) : epgIndex.get(channelId) ?? [];
  };

  // ---------------------------------------------------------------- playlists
  const replaceCatalogFor = (playlistId: string, data: { channels: Channel[]; vod: VodItem[]; series: SeriesItem[] }) => {
    setChannels((prev) => [...prev.filter((c) => c.playlistId !== playlistId), ...data.channels]);
    setVodAll((prev) => [...prev.filter((v) => v.playlistId !== playlistId), ...data.vod]);
    setSeriesAll((prev) => {
      // Keep episodes already fetched for series that still exist after a refresh.
      const loaded = new Map(prev.filter((s) => s.playlistId === playlistId && s.seasonsLoaded).map((s) => [s.id, s]));
      const next = data.series.map((s) => (s.seasonsLoaded ? s : loaded.has(s.id) ? { ...s, seasons: loaded.get(s.id)!.seasons, seasonsLoaded: true } : s));
      return [...prev.filter((s) => s.playlistId !== playlistId), ...next];
    });
  };

  const downloadPlaylist = async (
    pl: Playlist,
    source: { content?: string }
  ): Promise<{ channels: Channel[]; vod: VodItem[]; series: SeriesItem[]; epgUrl?: string; expiresAt?: string }> => {
    if (pl.type === 'xtream') {
      const creds = credentialsFor(pl);
      if (!creds) throw new Error('Senha ausente. Exclua e adicione a lista novamente com a senha.');
      const cat = await fetchCatalog(creds, pl.id, {
        // The native player plays MPEG-TS directly; the browser needs HLS.
        preferHls: !(canUseNativePlayer() && settings.useNativePlayer),
        onProgress: (step) => setSyncStatus({ playlistId: pl.id, step }),
      });
      return { channels: cat.channels, vod: cat.vod, series: cat.series, epgUrl: pl.epgUrl || cat.epgUrl, expiresAt: cat.account.expiresAt };
    }
    let content = source.content || '';
    if (!content) {
      if (!pl.url) throw new Error('Lista sem URL.');
      setSyncStatus({ playlistId: pl.id, step: 'Baixando lista…' });
      content = await httpGetText(pl.url, { timeoutMs: 180_000 });
    }
    setSyncStatus({ playlistId: pl.id, step: 'Organizando canais, filmes e séries…' });
    const parsed = await parseM3uAsync(content, pl.id);
    return { ...parsed, epgUrl: pl.epgUrl || parsed.epgUrl };
  };

  const syncEpgInBackground = (pl: Playlist, epgUrl: string | undefined, pool: Channel[]) => {
    if (!epgUrl) return;
    void importEpgFromUrl(epgUrl, pool).then((r) => {
      if (r.success) {
        setPlaylists((prev) => prev.map((p) => (p.id === pl.id ? { ...p, epgUrl, epgLastSync: new Date().toISOString() } : p)));
      } else {
        console.warn('Guia (EPG) não importado:', r.message);
      }
    });
  };

  const addPlaylist: AppContextValue['addPlaylist'] = async (name, type, source) => {
    const newPlaylist: Playlist = {
      id: `pl_${Date.now()}`,
      name: name.trim() || (type === 'xtream' ? 'Servidor Xtream' : 'Minha lista'),
      type,
      url: source.url?.trim() || undefined,
      username: source.username?.trim() || undefined,
      password: source.password || undefined,
      epgUrl: source.epgUrl?.trim() || undefined,
      channelCount: 0,
      lastSync: new Date().toISOString(),
      isActive: true,
      autoSyncMinutes: 1440,
    };
    setSyncStatus({ playlistId: newPlaylist.id, step: 'Conectando…' });
    try {
      const data = await downloadPlaylist(newPlaylist, { content: source.content });
      const total = data.channels.length + data.vod.length + data.series.length;
      if (total === 0) return { success: false, channelCount: 0, message: 'Nenhum canal, filme ou série válido encontrado.' };
      const saved: Playlist = {
        ...newPlaylist,
        epgUrl: data.epgUrl,
        expiresAt: data.expiresAt,
        channelCount: data.channels.length,
        vodCount: data.vod.length,
        seriesCount: data.series.length,
      };
      setPlaylists((prev) => [...prev, saved]);
      replaceCatalogFor(saved.id, data);
      syncEpgInBackground(saved, data.epgUrl, data.channels);
      return { success: true, channelCount: data.channels.length, vodCount: data.vod.length, seriesCount: data.series.length };
    } catch (e) {
      return { success: false, channelCount: 0, message: errorMessage(e) };
    } finally {
      setSyncStatus(null);
    }
  };

  const refreshPlaylist = useCallback(
    async (id: string): Promise<PlaylistResult> => {
      const pl = playlistsRef.current.find((p) => p.id === id);
      if (!pl) return { success: false, channelCount: 0, message: 'Lista não encontrada.' };
      if (pl.id === DEMO_PLAYLIST_ID) return { success: true, channelCount: pl.channelCount };
      if (pl.type === 'm3u' && !pl.url) {
        return { success: false, channelCount: pl.channelCount, message: 'Lista importada de arquivo: importe o arquivo novamente para atualizar.' };
      }
      setSyncStatus({ playlistId: id, step: 'Atualizando…' });
      try {
        const data = await downloadPlaylist(pl, {});
        if (data.channels.length + data.vod.length + data.series.length === 0) throw new Error('A lista voltou vazia; os dados antigos foram mantidos.');
        replaceCatalogFor(id, data);
        setPlaylists((prev) =>
          prev.map((p) =>
            p.id === id
              ? {
                  ...p,
                  epgUrl: data.epgUrl,
                  expiresAt: data.expiresAt ?? p.expiresAt,
                  channelCount: data.channels.length,
                  vodCount: data.vod.length,
                  seriesCount: data.series.length,
                  lastSync: new Date().toISOString(),
                  lastError: undefined,
                }
              : p
          )
        );
        syncEpgInBackground(pl, data.epgUrl, data.channels);
        return { success: true, channelCount: data.channels.length, vodCount: data.vod.length, seriesCount: data.series.length };
      } catch (e) {
        const message = errorMessage(e);
        setPlaylists((prev) => prev.map((p) => (p.id === id ? { ...p, lastError: message } : p)));
        return { success: false, channelCount: pl.channelCount, message };
      } finally {
        setSyncStatus(null);
      }
    },
    // downloadPlaylist reads settings; refreshing with stale settings is harmless.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [settings.useNativePlayer]
  );

  // Background auto-sync of stale lists and guides, once per app start.
  const autoSyncDone = useRef(false);
  useEffect(() => {
    if (!isHydrated || autoSyncDone.current) return;
    autoSyncDone.current = true;
    const now = Date.now();
    const run = async () => {
      for (const pl of playlistsRef.current) {
        if (!pl.isActive || pl.id === DEMO_PLAYLIST_ID) continue;
        const maxAge = (pl.autoSyncMinutes ?? 1440) * 60_000;
        if (now - Date.parse(pl.lastSync) > maxAge && (pl.url || pl.type === 'xtream')) {
          await refreshPlaylist(pl.id);
        } else if (pl.epgUrl && (!pl.epgLastSync || now - Date.parse(pl.epgLastSync) > 12 * 3600_000)) {
          syncEpgInBackground(pl, pl.epgUrl, channelsRef.current);
        }
      }
    };
    // Let the first screen render before network work starts.
    const t = setTimeout(() => void run(), 4000);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isHydrated]);

  const deletePlaylist = (id: string) => {
    setPlaylists((prev) => prev.filter((p) => p.id !== id));
    setChannels((prev) => prev.filter((c) => c.playlistId !== id));
    setVodAll((prev) => prev.filter((v) => v.playlistId !== id));
    setSeriesAll((prev) => prev.filter((s) => s.playlistId !== id));
  };

  const togglePlaylist = (id: string) => {
    setPlaylists((prev) => prev.map((p) => (p.id === id ? { ...p, isActive: !p.isActive } : p)));
  };

  const loadDemoContent = () => {
    if (playlists.some((p) => p.id === DEMO_PLAYLIST_ID)) return;
    const vod = INITIAL_VOD.map((v) => ({ ...v, playlistId: DEMO_PLAYLIST_ID }));
    const series = INITIAL_SERIES.map((s) => ({ ...s, playlistId: DEMO_PLAYLIST_ID, seasonsLoaded: true }));
    setPlaylists((prev) => [
      ...prev,
      { ...INITIAL_PLAYLISTS[0], channelCount: INITIAL_CHANNELS.length, vodCount: vod.length, seriesCount: series.length },
    ]);
    replaceCatalogFor(DEMO_PLAYLIST_ID, { channels: INITIAL_CHANNELS, vod, series });
    mergeEpg(generateSampleEpg());
    setStats((prev) => (prev.totalMinutesWatched === 0 ? INITIAL_STATS : prev));
  };

  // ---------------------------------------------------------------- derived catalog
  const activePlaylistIds = useMemo(() => new Set(playlists.filter((p) => p.isActive).map((p) => p.id)), [playlists]);
  const isKidsProfile = activeProfile?.isKids || false;

  const filteredChannels = useMemo(
    () =>
      channels.filter((c) => {
        if (!activePlaylistIds.has(c.playlistId)) return false;
        if (isKidsProfile) return isKidFriendly(c.groupTitle, c.name) || c.name.toLowerCase().includes('retro toons');
        return true;
      }),
    [channels, activePlaylistIds, isKidsProfile]
  );

  const vodItems = useMemo(
    () =>
      vodAll.filter((v) => {
        if (v.playlistId && !activePlaylistIds.has(v.playlistId)) return false;
        return !isKidsProfile || isKidFriendly(v.category);
      }),
    [vodAll, activePlaylistIds, isKidsProfile]
  );

  const seriesItems = useMemo(
    () =>
      seriesAll.filter((s) => {
        if (s.playlistId && !activePlaylistIds.has(s.playlistId)) return false;
        return !isKidsProfile || isKidFriendly(s.category);
      }),
    [seriesAll, activePlaylistIds, isKidsProfile]
  );

  // Channel numbers follow the full channel grid order (what the user sees as 01, 02…).
  const channelNumberById = useMemo(() => new Map(filteredChannels.map((c, i) => [c.id, i])), [filteredChannels]);

  const categories = useMemo(
    () => Array.from(new Set(filteredChannels.map((c) => c.groupTitle || 'Geral'))).sort((a, b) => a.localeCompare(b, 'pt-BR')),
    [filteredChannels]
  );

  // ---------------------------------------------------------------- my list (per profile)
  const [myListByProfile, setMyListByProfile] = useState<Record<string, string[]>>(() => {
    try {
      return JSON.parse(localStorage.getItem('nebula_mylist') || '{}');
    } catch {
      return {};
    }
  });
  useEffect(() => {
    try {
      localStorage.setItem('nebula_mylist', JSON.stringify(myListByProfile));
    } catch {
      /* storage full or unavailable */
    }
  }, [myListByProfile]);
  const profileKey = activeProfile?.id || 'default';
  const myList = myListByProfile[profileKey] ?? [];
  const toggleMyList = (contentId: string) => {
    setMyListByProfile((prev) => {
      const cur = prev[profileKey] ?? [];
      const next = cur.includes(contentId) ? cur.filter((id) => id !== contentId) : [contentId, ...cur];
      return { ...prev, [profileKey]: next };
    });
  };
  const isInMyList = (contentId: string) => myList.includes(contentId);

  // ---------------------------------------------------------------- favourites
  const favoriteSet = useMemo(() => new Set(favorites), [favorites]);
  const toggleFavorite = (channelId: string) => {
    setFavorites((prev) => (prev.includes(channelId) ? prev.filter((id) => id !== channelId) : [...prev, channelId]));
  };
  const isFavorite = (channelId: string) => favoriteSet.has(channelId);
  const channelsWithFav = useMemo(
    () => filteredChannels.map((c) => (favoriteSet.has(c.id) === !!c.isFavorite ? c : { ...c, isFavorite: favoriteSet.has(c.id) })),
    [filteredChannels, favoriteSet]
  );

  // ---------------------------------------------------------------- stats & history
  const trackWatchTime = (channelName: string, genre: string, minutes: number = 5) => {
    setStats((prev) => {
      const today = new Date().toDateString();
      const isNewDay = !prev.lastWatchedDate || new Date(prev.lastWatchedDate).toDateString() !== today;
      return {
        ...prev,
        totalMinutesWatched: prev.totalMinutesWatched + minutes,
        channelPlayCounts: { ...prev.channelPlayCounts, [channelName]: (prev.channelPlayCounts[channelName] || 0) + 1 },
        genreCounts: { ...prev.genreCounts, [genre]: (prev.genreCounts[genre] || 0) + 1 },
        daysActive: prev.daysActive + (isNewDay ? 1 : 0),
        lastWatchedDate: new Date().toISOString(),
      };
    });
  };

  const addToHistory = (item: Omit<WatchHistoryItem, 'id' | 'timestamp'>) => {
    const newItem: WatchHistoryItem = { ...item, id: `hist_${Date.now()}`, timestamp: new Date().toISOString() };
    setHistory((prev) => [newItem, ...prev.filter((h) => h.contentId !== item.contentId)].slice(0, 100));
  };
  const clearHistory = () => setHistory([]);

  // ---------------------------------------------------------------- progress
  const saveProgress = useCallback((contentId: string, positionSeconds: number, durationSeconds: number) => {
    setProgress((prev) => updateProgress(prev, contentId, positionSeconds, durationSeconds));
    setHistory((prev) => prev.map((h) => (h.contentId === contentId ? { ...h, positionSeconds: Math.floor(positionSeconds), durationSeconds: durationSeconds || h.durationSeconds } : h)));
  }, []);
  const getResumeSeconds = (contentId: string) => resumePosition(progress, contentId);
  const getProgressFraction = (contentId: string) => progressFraction(progress, contentId);
  const continueWatchingItems = useMemo(() => continueWatching(history, progress), [history, progress]);

  // ---------------------------------------------------------------- playback
  const useNative = canUseNativePlayer() && settings.useNativePlayer;

  /** Opens a stream in the native Media3 player and records what happened when it closes. */
  const runNative = async (
    stream: ActiveStream,
    opts: { queue?: Channel[]; queueIndex?: number; nextTitle?: string; genre: string }
  ) => {
    const queueItems: NativeQueueItem[] | undefined = opts.queue?.map((c) => ({
      id: c.id,
      title: c.name,
      url: c.streamUrl,
      logoUrl: c.logoUrl,
      // "Now playing" line shown in the native zapping banner.
      subtitle: getChannelCurrentProgram(c.id)?.title,
      number: (channelNumberById.get(c.id) ?? -1) + 1 || undefined,
    }));
    try {
      const res = await playNative({
        url: stream.streamUrl,
        title: stream.title,
        subtitle: stream.subtitle,
        isLive: stream.isLive,
        startPositionMs: Math.floor((stream.startPositionSeconds ?? 0) * 1000),
        queue: queueItems,
        queueIndex: opts.queueIndex,
        bufferMode: settings.bufferMode,
        nextTitle: opts.nextTitle,
      });
      if (stream.isLive) {
        const last = opts.queue?.[res.queueIndex];
        if (last && last.id !== stream.id) {
          addToHistory({ contentId: last.id, contentType: 'channel', title: last.name, subtitle: last.groupTitle, posterUrl: last.logoUrl, streamUrl: last.streamUrl, positionSeconds: 0 });
        }
        return res;
      }
      const watchedMin = Math.round(res.positionMs / 60000);
      if (watchedMin > 0) trackWatchTime(stream.series?.title || stream.title, opts.genre, Math.min(watchedMin, 240));
      // An empty result (player killed by the system) must not wipe saved progress.
      if (res.positionMs > 0) saveProgress(stream.episode?.id || stream.id, res.positionMs / 1000, res.durationMs / 1000);
      return res;
    } catch (e) {
      console.error('Player nativo falhou, usando o player web:', e);
      setCurrentStream(stream);
      setIsPlayerOpen(true);
      return null;
    }
  };

  const openStream = (stream: ActiveStream) => {
    setCurrentStream(stream);
    setIsPlayerOpen(true);
  };

  const playChannel = (channel: Channel, queue?: Channel[]) => {
    const currentProg = getChannelCurrentProgram(channel.id);
    const active: ActiveStream = {
      id: channel.id,
      title: channel.name,
      subtitle: currentProg?.title || channel.groupTitle || 'Ao Vivo',
      streamUrl: channel.streamUrl,
      logoUrl: channel.logoUrl,
      isLive: true,
      channel,
    };
    addToHistory({
      contentId: channel.id,
      contentType: 'channel',
      title: channel.name,
      subtitle: currentProg?.title || 'Ao Vivo',
      posterUrl: channel.logoUrl,
      streamUrl: channel.streamUrl,
      positionSeconds: 0,
    });
    trackWatchTime(channel.name, channel.groupTitle || 'Ao Vivo', 5);

    if (useNative) {
      // Zapping list: the channel's own category keeps the bridge payload small.
      const pool = queue ?? filteredChannels.filter((c) => (c.groupTitle || 'Geral') === (channel.groupTitle || 'Geral'));
      const list = pool.length > 3000 ? pool.slice(0, 3000) : pool;
      let idx = list.findIndex((c) => c.id === channel.id);
      const finalList = idx === -1 ? [channel, ...list] : list;
      if (idx === -1) idx = 0;
      void runNative(active, { queue: finalList, queueIndex: idx, genre: channel.groupTitle || 'Ao Vivo' });
      return;
    }
    openStream(active);
  };

  const playVod = (vod: VodItem, fromStart = false) => {
    const active: ActiveStream = {
      id: vod.id,
      title: vod.title,
      subtitle: [vod.category, vod.year || null, vod.durationMinutes ? `${vod.durationMinutes} min` : null].filter(Boolean).join(' • '),
      streamUrl: vod.streamUrl,
      logoUrl: vod.posterUrl,
      isLive: false,
      vod,
      startPositionSeconds: fromStart ? 0 : resumePosition(progress, vod.id),
    };
    setSelectedVodModal(null);
    addToHistory({
      contentId: vod.id,
      contentType: 'vod',
      title: vod.title,
      subtitle: [vod.category, vod.year || null].filter(Boolean).join(' • '),
      posterUrl: vod.posterUrl,
      streamUrl: vod.streamUrl,
      positionSeconds: active.startPositionSeconds ?? 0,
      durationSeconds: vod.durationMinutes ? vod.durationMinutes * 60 : undefined,
    });
    if (useNative) {
      void runNative(active, { genre: vod.category });
      return;
    }
    trackWatchTime(vod.title, vod.category, 10);
    openStream(active);
  };

  const buildEpisodeStream = (series: SeriesItem, seasonNumber: number, episode: Episode, fromStart: boolean): ActiveStream => ({
    id: episode.id,
    title: `${series.title} - T${seasonNumber}:E${episode.episodeNumber}`,
    subtitle: episode.title,
    streamUrl: episode.streamUrl,
    logoUrl: episode.stillUrl || series.posterUrl,
    isLive: false,
    series,
    episode: { id: episode.id, title: episode.title, episodeNumber: episode.episodeNumber, seasonNumber, streamUrl: episode.streamUrl },
    startPositionSeconds: fromStart ? 0 : resumePosition(progress, episode.id),
  });

  const playEpisode = (series: SeriesItem, seasonNumber: number, episode: Episode, fromStart = false) => {
    const active = buildEpisodeStream(series, seasonNumber, episode, fromStart);
    setSelectedSeriesModal(null);
    addToHistory({
      contentId: episode.id,
      contentType: 'series',
      title: active.title,
      subtitle: episode.title,
      posterUrl: series.posterUrl,
      streamUrl: episode.streamUrl,
      positionSeconds: active.startPositionSeconds ?? 0,
      durationSeconds: episode.durationMinutes ? episode.durationMinutes * 60 : undefined,
      seriesId: series.id,
      seasonNumber,
      episodeNumber: episode.episodeNumber,
    });

    if (useNative) {
      const next = findNextEpisode(series, seasonNumber, episode.id);
      void runNative(active, {
        genre: series.category,
        nextTitle: next ? `T${next.seasonNumber}:E${next.episode.episodeNumber} · ${next.episode.title}` : undefined,
      }).then((res) => {
        if (res && next && (res.playNext || (res.completed && settings.autoplayNextEpisode))) {
          playEpisode(series, next.seasonNumber, next.episode, true);
        }
      });
      return;
    }
    trackWatchTime(series.title, series.category, 10);
    openStream(active);
  };

  const nextEpisodeRef = () => {
    const s = currentStream;
    if (!s?.series || !s.episode) return null;
    const series = seriesAll.find((x) => x.id === s.series!.id) ?? s.series;
    return { series, next: findNextEpisode(series, s.episode.seasonNumber, s.episode.id) };
  };

  const playNextEpisode = () => {
    const ref = nextEpisodeRef();
    if (!ref?.next) return false;
    playEpisode(ref.series, ref.next.seasonNumber, ref.next.episode, true);
    return true;
  };

  const getNextEpisodeTitle = () => {
    const ref = nextEpisodeRef();
    return ref?.next ? `T${ref.next.seasonNumber}:E${ref.next.episode.episodeNumber} · ${ref.next.episode.title}` : null;
  };

  const playDirectStream = (stream: ActiveStream) => openStream(stream);
  const closePlayer = () => setIsPlayerOpen(false);

  // ---------------------------------------------------------------- details (lazy)
  const replaceSeries = (updated: SeriesItem) => {
    setSeriesAll((prev) => prev.map((s) => (s.id === updated.id ? updated : s)));
    setSelectedSeriesModal((cur) => (cur && cur.id === updated.id ? updated : cur));
  };
  const replaceVod = (updated: VodItem) => {
    setVodAll((prev) => prev.map((v) => (v.id === updated.id ? updated : v)));
    setSelectedVodModal((cur) => (cur && cur.id === updated.id ? updated : cur));
  };

  const withTmdbSeries = async (s: SeriesItem): Promise<SeriesItem> => {
    if (!settings.tmdbApiKey || (s.backdropUrl && s.posterUrl && s.overview)) return s;
    const meta = await lookupTmdb(settings.tmdbApiKey, 'tv', s.title, s.year);
    if (!meta) return s;
    return {
      ...s,
      tmdbId: s.tmdbId || meta.tmdbId,
      posterUrl: s.posterUrl || meta.posterUrl || '',
      backdropUrl: s.backdropUrl || meta.backdropUrl,
      overview: s.overview || meta.overview || '',
      rating: s.rating || meta.rating || 0,
      year: s.year || meta.year,
    };
  };

  const withTmdbVod = async (v: VodItem): Promise<VodItem> => {
    if (!settings.tmdbApiKey || (v.backdropUrl && v.posterUrl && v.description)) return v;
    const meta = await lookupTmdb(settings.tmdbApiKey, 'movie', v.title, v.year || undefined);
    if (!meta) return v;
    return {
      ...v,
      tmdbId: v.tmdbId || meta.tmdbId,
      posterUrl: v.posterUrl || meta.posterUrl || '',
      backdropUrl: v.backdropUrl || meta.backdropUrl,
      description: v.description || meta.overview || '',
      rating: v.rating || meta.rating || 0,
      year: v.year || meta.year || 0,
    };
  };

  const loadSeriesDetails = async (series: SeriesItem): Promise<SeriesItem> => {
    let s = series;
    if (!s.seasonsLoaded && s.sourceId) {
      const creds = credentialsFor(playlists.find((p) => p.id === s.playlistId));
      if (creds) s = await fetchSeriesInfo(creds, s);
    }
    s = await withTmdbSeries(s).catch(() => s);
    if (s !== series) replaceSeries(s);
    return s;
  };

  const loadVodDetails = async (vod: VodItem): Promise<VodItem> => {
    let v = vod;
    if (v.sourceId && (!v.description || !v.durationMinutes)) {
      const creds = credentialsFor(playlists.find((p) => p.id === v.playlistId));
      if (creds) v = await fetchVodInfo(creds, v).catch(() => v);
    }
    v = await withTmdbVod(v).catch(() => v);
    if (v !== vod) replaceVod(v);
    return v;
  };

  const enrichInFlight = useRef(new Set<string>());
  const enrichArtwork = (kind: 'vod' | 'series', id: string) => {
    if (!settings.tmdbApiKey || enrichInFlight.current.has(id)) return;
    enrichInFlight.current.add(id);
    if (kind === 'vod') {
      const v = vodAll.find((x) => x.id === id);
      if (v) void withTmdbVod(v).then((u) => u !== v && replaceVod(u));
    } else {
      const s = seriesAll.find((x) => x.id === id);
      if (s) void withTmdbSeries(s).then((u) => u !== s && replaceSeries(u));
    }
  };

  const resumeHistoryItem = (item: WatchHistoryItem) => {
    if (item.contentType === 'channel') {
      const ch = channelById.get(item.contentId);
      if (ch) playChannel(ch);
      return;
    }
    if (item.contentType === 'vod') {
      const vod = vodAll.find((v) => v.id === item.contentId);
      if (vod) playVod(vod);
      else openStream({ id: item.contentId, title: item.title, subtitle: item.subtitle, streamUrl: item.streamUrl, isLive: false, startPositionSeconds: resumePosition(progress, item.contentId) });
      return;
    }
    const series = item.seriesId ? seriesAll.find((s) => s.id === item.seriesId) : undefined;
    if (series) {
      for (const season of series.seasons) {
        const ep = season.episodes.find((e) => e.id === item.contentId);
        if (ep) {
          playEpisode(series, season.seasonNumber, ep);
          return;
        }
      }
      const ref = episodeToResume(series, progress);
      if (ref) {
        playEpisode(series, ref.seasonNumber, ref.episode);
        return;
      }
    }
    openStream({ id: item.contentId, title: item.title, subtitle: item.subtitle, streamUrl: item.streamUrl, isLive: false, startPositionSeconds: resumePosition(progress, item.contentId) });
  };

  // ---------------------------------------------------------------- settings
  const updateSettings = (newPartial: Partial<AppSettings>) => setSettings((prev) => ({ ...prev, ...newPartial }));
  const toggleTvMode = () => setSettings((prev) => ({ ...prev, tvMode: !prev.tvMode }));

  const isLite = settings.liteMode === 'on' || (settings.liteMode === 'auto' && deviceProfile.isLowEnd);
  useEffect(() => {
    document.documentElement.classList.toggle('lite', isLite);
  }, [isLite]);

  // TV boxes have no mouse: start in remote-control mode there.
  const tvDefaultApplied = useRef(false);
  useEffect(() => {
    if (tvDefaultApplied.current) return;
    tvDefaultApplied.current = true;
    if ((isNativeApp() || deviceProfile.isAndroidTv) && !localStorage.getItem('nebula_tv_default_applied')) {
      localStorage.setItem('nebula_tv_default_applied', '1');
      setSettings((prev) => ({ ...prev, tvMode: true }));
    }
  }, [deviceProfile.isAndroidTv]);

  return (
    <AppContext.Provider
      value={{
        activeTab,
        setActiveTab,
        isHydrated,
        deviceProfile,
        isLite,
        profiles,
        activeProfile,
        isGateLocked,
        selectProfile,
        lockToProfileGate,
        updateProfile,
        createProfile,
        deleteProfile,
        playlists,
        syncStatus,
        addPlaylist,
        deletePlaylist,
        togglePlaylist,
        refreshPlaylist,
        loadDemoContent,
        channels,
        filteredChannels: channelsWithFav,
        categories,
        favorites,
        myList,
        toggleMyList,
        isInMyList,
        toggleFavorite,
        isFavorite,
        currentStream,
        isPlayerOpen,
        playChannel,
        playVod,
        playEpisode,
        playDirectStream,
        playNextEpisode,
        getNextEpisodeTitle,
        closePlayer,
        history,
        addToHistory,
        clearHistory,
        resumeHistoryItem,
        saveProgress,
        getResumeSeconds,
        getProgressFraction,
        progressMap: progress,
        continueWatchingItems,
        epgPrograms,
        getChannelCurrentProgram,
        getChannelPrograms,
        importXmltv,
        importEpgFromUrl: (url: string) => importEpgFromUrl(url),
        vodItems,
        seriesItems,
        selectedVodModal,
        setSelectedVodModal,
        selectedSeriesModal,
        setSelectedSeriesModal,
        loadSeriesDetails,
        loadVodDetails,
        enrichArtwork,
        stats,
        trackWatchTime,
        isWrappedOpen,
        setIsWrappedOpen,
        settings,
        updateSettings,
        searchQuery,
        setSearchQuery,
        tvMode: settings.tvMode,
        toggleTvMode,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within an AppProvider');
  return context;
};

