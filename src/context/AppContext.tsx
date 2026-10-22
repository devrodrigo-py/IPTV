import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  AppSettings,
  Channel,
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
  loadProfiles,
  saveProfiles,
  loadActiveProfileId,
  saveActiveProfileId,
  loadPlaylists,
  savePlaylists,
  loadChannels,
  saveChannels,
  loadFavorites,
  saveFavorites,
  loadHistory,
  saveHistory,
  loadEpg,
  saveEpg,
  loadSettings,
  saveSettings,
  loadStats,
  saveStats,
  loadVod,
  saveVod,
  loadSeries,
  saveSeries,
} from '../data/storage';
import { parseM3u } from '../data/m3uParser';
import { parseXmltv } from '../data/xmltvParser';

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
  | 'search';

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
}

interface AppContextValue {
  // Navigation
  activeTab: TabType;
  setActiveTab: (tab: TabType) => void;

  // Profiles
  profiles: UserProfile[];
  activeProfile: UserProfile | null;
  isGateLocked: boolean;
  selectProfile: (profile: UserProfile, pinAttempt?: string) => boolean;
  lockToProfileGate: () => void;
  updateProfile: (profile: UserProfile) => void;
  createProfile: (profileData: Omit<UserProfile, 'id' | 'createdAt'>) => void;
  deleteProfile: (id: string) => void;

  // Playlists
  playlists: Playlist[];
  addPlaylist: (
    name: string,
    type: PlaylistType,
    source: { url?: string; content?: string; username?: string; password?: string }
  ) => Promise<{ success: boolean; channelCount: number; message?: string }>;
  deletePlaylist: (id: string) => void;
  togglePlaylist: (id: string) => void;
  refreshPlaylist: (id: string) => Promise<void>;

  // Channels
  channels: Channel[];
  filteredChannels: Channel[];
  categories: string[];
  favorites: string[];
  toggleFavorite: (channelId: string) => void;
  isFavorite: (channelId: string) => boolean;

  // Player
  currentStream: ActiveStream | null;
  isPlayerOpen: boolean;
  playChannel: (channel: Channel) => void;
  playVod: (vod: VodItem) => void;
  playEpisode: (series: SeriesItem, seasonNumber: number, episode: any) => void;
  playDirectStream: (stream: ActiveStream) => void;
  closePlayer: () => void;

  // History
  history: WatchHistoryItem[];
  addToHistory: (item: Omit<WatchHistoryItem, 'id' | 'timestamp'>) => void;
  clearHistory: () => void;

  // EPG
  epgPrograms: EpgProgram[];
  getChannelCurrentProgram: (channelId: string) => EpgProgram | undefined;
  getChannelPrograms: (channelId: string) => EpgProgram[];
  importXmltv: (content: string) => { success: boolean; programCount: number };

  // VOD & Series
  vodItems: VodItem[];
  seriesItems: SeriesItem[];
  selectedVodModal: VodItem | null;
  setSelectedVodModal: (vod: VodItem | null) => void;
  selectedSeriesModal: SeriesItem | null;
  setSelectedSeriesModal: (series: SeriesItem | null) => void;

  // Stats & Wrapped
  stats: WatchStats;
  trackWatchTime: (channelName: string, genre: string, minutes?: number) => void;
  isWrappedOpen: boolean;
  setIsWrappedOpen: (open: boolean) => void;

  // Settings
  settings: AppSettings;
  updateSettings: (newSettings: Partial<AppSettings>) => void;

  // Search
  searchQuery: string;
  setSearchQuery: (q: string) => void;

  // TV remote mode
  tvMode: boolean;
  toggleTvMode: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [searchQuery, setSearchQuery] = useState('');

  // Profiles
  const [profiles, setProfiles] = useState<UserProfile[]>(loadProfiles);
  const [activeProfile, setActiveProfile] = useState<UserProfile | null>(() => {
    const loaded = loadProfiles();
    const activeId = loadActiveProfileId();
    return loaded.find((p) => p.id === activeId) || loaded[0] || null;
  });
  const [isGateLocked, setIsGateLocked] = useState(false);

  // Data
  const [playlists, setPlaylists] = useState<Playlist[]>(loadPlaylists);
  const [channels, setChannels] = useState<Channel[]>(loadChannels);
  const [favorites, setFavorites] = useState<string[]>(loadFavorites);
  const [history, setHistory] = useState<WatchHistoryItem[]>(loadHistory);
  const [epgPrograms, setEpgPrograms] = useState<EpgProgram[]>(loadEpg);
  const [vodItems, setVodItems] = useState<VodItem[]>(loadVod);
  const [seriesItems, setSeriesItems] = useState<SeriesItem[]>(loadSeries);
  const [stats, setStats] = useState<WatchStats>(loadStats);
  const [settings, setSettings] = useState<AppSettings>(loadSettings);

  // Player state
  const [currentStream, setCurrentStream] = useState<ActiveStream | null>(null);
  const [isPlayerOpen, setIsPlayerOpen] = useState(false);

  // Modals
  const [selectedVodModal, setSelectedVodModal] = useState<VodItem | null>(null);
  const [selectedSeriesModal, setSelectedSeriesModal] = useState<SeriesItem | null>(null);
  const [isWrappedOpen, setIsWrappedOpen] = useState(false);

  // Save changes to localStorage
  useEffect(() => {
    saveProfiles(profiles);
  }, [profiles]);

  useEffect(() => {
    if (activeProfile) {
      saveActiveProfileId(activeProfile.id);
    }
  }, [activeProfile]);

  useEffect(() => {
    savePlaylists(playlists);
  }, [playlists]);

  useEffect(() => {
    saveChannels(channels);
  }, [channels]);

  useEffect(() => {
    saveFavorites(favorites);
  }, [favorites]);

  useEffect(() => {
    saveHistory(history);
  }, [history]);

  useEffect(() => {
    saveEpg(epgPrograms);
  }, [epgPrograms]);

  useEffect(() => {
    saveSettings(settings);
  }, [settings]);

  useEffect(() => {
    saveStats(stats);
  }, [stats]);

  // Profile actions
  const selectProfile = (profile: UserProfile, pinAttempt?: string): boolean => {
    if (profile.pin && profile.pin !== pinAttempt) {
      return false;
    }
    setActiveProfile(profile);
    setIsGateLocked(false);
    return true;
  };

  const lockToProfileGate = () => {
    setIsGateLocked(true);
  };

  const updateProfile = (updated: UserProfile) => {
    setProfiles((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
    if (activeProfile?.id === updated.id) {
      setActiveProfile(updated);
    }
  };

  const createProfile = (data: Omit<UserProfile, 'id' | 'createdAt'>) => {
    const newProf: UserProfile = {
      ...data,
      id: `prof_${Date.now()}`,
      createdAt: new Date().toISOString(),
    };
    setProfiles((prev) => [...prev, newProf]);
  };

  const deleteProfile = (id: string) => {
    if (profiles.length <= 1) return;
    setProfiles((prev) => prev.filter((p) => p.id !== id));
    if (activeProfile?.id === id) {
      setActiveProfile(profiles.find((p) => p.id !== id) || null);
    }
  };

  // Playlists
  const addPlaylist = async (
    name: string,
    type: PlaylistType,
    source: { url?: string; content?: string; username?: string; password?: string }
  ): Promise<{ success: boolean; channelCount: number; message?: string }> => {
    const newId = `pl_${Date.now()}`;
    let parsedChannels: Channel[] = [];

    if (type === 'm3u') {
      let rawContent = source.content || '';
      if (source.url && !source.content) {
        try {
          const res = await fetch(source.url);
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          rawContent = await res.text();
        } catch (err: any) {
          return {
            success: false,
            channelCount: 0,
            message: `Falha ao baixar URL: ${err.message || 'Verifique a conexão ou CORS'}.`,
          };
        }
      }

      if (!rawContent) {
        return { success: false, channelCount: 0, message: 'Conteúdo M3U vazio.' };
      }

      const parseResult = parseM3u(rawContent, newId);
      parsedChannels = parseResult.channels;
    } else if (type === 'xtream') {
      // Xtream Codes integration mock/direct parse
      parsedChannels = [
        {
          id: `ch_${newId}_1`,
          playlistId: newId,
          name: `${name} Live Stream 1`,
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          groupTitle: 'Geral',
          resolution: 'FHD',
        },
        {
          id: `ch_${newId}_2`,
          playlistId: newId,
          name: `${name} Cinema HD`,
          streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
          groupTitle: 'Filmes & Séries',
          resolution: '4K',
        },
      ];
    }

    if (parsedChannels.length === 0) {
      return { success: false, channelCount: 0, message: 'Nenhum canal válido encontrado.' };
    }

    const newPlaylist: Playlist = {
      id: newId,
      name,
      type,
      url: source.url,
      username: source.username,
      password: source.password ? '••••••••' : undefined,
      channelCount: parsedChannels.length,
      lastSync: new Date().toISOString(),
      isActive: true,
      autoSyncMinutes: 1440,
    };

    setPlaylists((prev) => [...prev, newPlaylist]);
    setChannels((prev) => [...prev, ...parsedChannels]);

    return {
      success: true,
      channelCount: parsedChannels.length,
    };
  };

  const deletePlaylist = (id: string) => {
    setPlaylists((prev) => prev.filter((p) => p.id !== id));
    setChannels((prev) => prev.filter((c) => c.playlistId !== id));
  };

  const togglePlaylist = (id: string) => {
    setPlaylists((prev) =>
      prev.map((p) => (p.id === id ? { ...p, isActive: !p.isActive } : p))
    );
  };

  const refreshPlaylist = async (id: string) => {
    const pl = playlists.find((p) => p.id === id);
    if (!pl || !pl.url) return;
    try {
      const res = await fetch(pl.url);
      if (res.ok) {
        const text = await res.text();
        const parsed = parseM3u(text, id);
        if (parsed.channels.length > 0) {
          setChannels((prev) => [
            ...prev.filter((c) => c.playlistId !== id),
            ...parsed.channels,
          ]);
          setPlaylists((prev) =>
            prev.map((p) =>
              p.id === id
                ? { ...p, channelCount: parsed.channels.length, lastSync: new Date().toISOString() }
                : p
            )
          );
        }
      }
    } catch (e) {
      console.error('Failed refreshing playlist:', e);
    }
  };

  // Filter channels based on active playlists and kids mode
  const activePlaylistIds = new Set(playlists.filter((p) => p.isActive).map((p) => p.id));
  const isKidsProfile = activeProfile?.isKids || false;

  const filteredChannels = channels.filter((c) => {
    if (!activePlaylistIds.has(c.playlistId)) return false;
    if (isKidsProfile) {
      const grp = (c.groupTitle || '').toLowerCase();
      const isKidFriendly =
        grp.includes('infantil') ||
        grp.includes('desenho') ||
        grp.includes('kids') ||
        grp.includes('música') ||
        grp.includes('documentários') ||
        c.name.toLowerCase().includes('retro toons');
      return isKidFriendly;
    }
    return true;
  });

  // Unique categories
  const categories = Array.from(
    new Set(filteredChannels.map((c) => c.groupTitle || 'Geral'))
  ).sort();

  // Favorites
  const toggleFavorite = (channelId: string) => {
    setFavorites((prev) => {
      const exists = prev.includes(channelId);
      const next = exists ? prev.filter((id) => id !== channelId) : [...prev, channelId];
      // also update channel obj isFavorite
      setChannels((chList) =>
        chList.map((ch) => (ch.id === channelId ? { ...ch, isFavorite: !exists } : ch))
      );
      return next;
    });
  };

  const isFavorite = (channelId: string) => favorites.includes(channelId);

  // Player controls & watch tracking
  const trackWatchTime = (channelName: string, genre: string, minutes: number = 5) => {
    setStats((prev) => {
      const currentChCount = prev.channelPlayCounts[channelName] || 0;
      const currentGenreCount = prev.genreCounts[genre] || 0;
      return {
        ...prev,
        totalMinutesWatched: prev.totalMinutesWatched + minutes,
        channelPlayCounts: {
          ...prev.channelPlayCounts,
          [channelName]: currentChCount + 1,
        },
        genreCounts: {
          ...prev.genreCounts,
          [genre]: currentGenreCount + 1,
        },
        lastWatchedDate: new Date().toISOString(),
      };
    });
  };

  const addToHistory = (item: Omit<WatchHistoryItem, 'id' | 'timestamp'>) => {
    const newItem: WatchHistoryItem = {
      ...item,
      id: `hist_${Date.now()}`,
      timestamp: new Date().toISOString(),
    };
    setHistory((prev) => [newItem, ...prev.filter((h) => h.contentId !== item.contentId)].slice(0, 50));
  };

  const clearHistory = () => {
    setHistory([]);
  };

  const playChannel = (channel: Channel) => {
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
    setCurrentStream(active);
    setIsPlayerOpen(true);
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
  };

  const playVod = (vod: VodItem) => {
    const active: ActiveStream = {
      id: vod.id,
      title: vod.title,
      subtitle: `${vod.category} • ${vod.year} • ${vod.durationMinutes} min`,
      streamUrl: vod.streamUrl,
      logoUrl: vod.posterUrl,
      isLive: false,
      vod,
    };
    setCurrentStream(active);
    setIsPlayerOpen(true);
    setSelectedVodModal(null);
    addToHistory({
      contentId: vod.id,
      contentType: 'vod',
      title: vod.title,
      subtitle: `${vod.category} • ${vod.year}`,
      posterUrl: vod.posterUrl,
      streamUrl: vod.streamUrl,
      positionSeconds: 0,
      durationSeconds: vod.durationMinutes * 60,
    });
    trackWatchTime(vod.title, vod.category, 10);
  };

  const playEpisode = (series: SeriesItem, seasonNumber: number, episode: any) => {
    const active: ActiveStream = {
      id: episode.id,
      title: `${series.title} - T${seasonNumber}:E${episode.episodeNumber}`,
      subtitle: episode.title,
      streamUrl: episode.streamUrl,
      logoUrl: episode.stillUrl || series.posterUrl,
      isLive: false,
      series,
      episode: {
        id: episode.id,
        title: episode.title,
        episodeNumber: episode.episodeNumber,
        seasonNumber,
        streamUrl: episode.streamUrl,
      },
    };
    setCurrentStream(active);
    setIsPlayerOpen(true);
    setSelectedSeriesModal(null);
    addToHistory({
      contentId: episode.id,
      contentType: 'series',
      title: `${series.title} - T${seasonNumber}:E${episode.episodeNumber}`,
      subtitle: episode.title,
      posterUrl: series.posterUrl,
      streamUrl: episode.streamUrl,
      positionSeconds: 0,
      durationSeconds: episode.durationMinutes * 60,
    });
    trackWatchTime(series.title, series.category, 10);
  };

  const playDirectStream = (stream: ActiveStream) => {
    setCurrentStream(stream);
    setIsPlayerOpen(true);
  };

  const closePlayer = () => {
    setIsPlayerOpen(false);
  };

  // EPG
  const getChannelCurrentProgram = (channelId: string): EpgProgram | undefined => {
    const now = new Date().getTime();
    return epgPrograms.find((p) => {
      if (p.channelId !== channelId) return false;
      const start = new Date(p.startUtc).getTime();
      const end = new Date(p.endUtc).getTime();
      return now >= start && now <= end;
    });
  };

  const getChannelPrograms = (channelId: string): EpgProgram[] => {
    return epgPrograms
      .filter((p) => p.channelId === channelId)
      .sort((a, b) => new Date(a.startUtc).getTime() - new Date(b.startUtc).getTime());
  };

  const importXmltv = (content: string) => {
    const res = parseXmltv(content);
    if (res.programs.length > 0) {
      setEpgPrograms((prev) => [...prev, ...res.programs]);
      return { success: true, programCount: res.programs.length };
    }
    return { success: false, programCount: 0 };
  };

  // Settings
  const updateSettings = (newPartial: Partial<AppSettings>) => {
    setSettings((prev) => ({ ...prev, ...newPartial }));
  };

  const toggleTvMode = () => {
    setSettings((prev) => ({ ...prev, tvMode: !prev.tvMode }));
  };

  return (
    <AppContext.Provider
      value={{
        activeTab,
        setActiveTab,
        profiles,
        activeProfile,
        isGateLocked,
        selectProfile,
        lockToProfileGate,
        updateProfile,
        createProfile,
        deleteProfile,
        playlists,
        addPlaylist,
        deletePlaylist,
        togglePlaylist,
        refreshPlaylist,
        channels,
        filteredChannels,
        categories,
        favorites,
        toggleFavorite,
        isFavorite,
        currentStream,
        isPlayerOpen,
        playChannel,
        playVod,
        playEpisode,
        playDirectStream,
        closePlayer,
        history,
        addToHistory,
        clearHistory,
        epgPrograms,
        getChannelCurrentProgram,
        getChannelPrograms,
        importXmltv,
        vodItems,
        seriesItems,
        selectedVodModal,
        setSelectedVodModal,
        selectedSeriesModal,
        setSelectedSeriesModal,
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
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
