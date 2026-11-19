import React, { useEffect, useRef, useState } from 'react';
import {
  Play,
  Pause,
  Volume2,
  VolumeX,
  Maximize,
  Minimize,
  RotateCcw,
  Settings as SettingsIcon,
  Tv,
  List,
  X,
  Radio,
  PictureInPicture,
  Heart,
  ChevronLeft,
  ChevronRight,
  Sliders,
  Check,
  Languages,
  SkipForward,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { bufferSeconds, detectEngine } from './streamEngine';

type HlsInstance = import('hls.js').default;
type MpegtsPlayer = import('mpegts.js').default.Player;

interface TrackOption {
  id: number;
  label: string;
}

const MAX_AUTO_RETRIES = 5;
const NEXT_EPISODE_LEAD_SECONDS = 25;

export const VideoPlayer: React.FC = () => {
  const {
    currentStream,
    isPlayerOpen,
    closePlayer,
    filteredChannels,
    playChannel,
    isFavorite,
    toggleFavorite,
    saveProgress,
    settings,
    playNextEpisode,
    getNextEpisodeTitle,
  } = useApp();

  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hlsRef = useRef<HlsInstance | null>(null);
  const tsRef = useRef<MpegtsPlayer | null>(null);
  const retryRef = useRef(0);
  const retryTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastSavedRef = useRef(0);
  const startedStreamRef = useRef<unknown>(null);

  const [isPlaying, setIsPlaying] = useState(true);
  const [isMuted, setIsMuted] = useState(false);
  const [volume, setVolume] = useState(0.8);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [aspectRatio, setAspectRatio] = useState<'fit' | 'fill' | '16:9' | '4:3'>('fit');
  const [isBuffering, setIsBuffering] = useState(true);
  const [hasError, setHasError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [showControls, setShowControls] = useState(true);
  const [showDrawer, setShowDrawer] = useState(false);
  const [showQualityMenu, setShowQualityMenu] = useState(false);
  const [showTracksMenu, setShowTracksMenu] = useState(false);
  const [availableLevels, setAvailableLevels] = useState<{ id: number; height: number; bitrate: number }[]>([]);
  const [currentLevel, setCurrentLevel] = useState<number>(-1); // -1 is auto
  const [audioTracks, setAudioTracks] = useState<TrackOption[]>([]);
  const [currentAudio, setCurrentAudio] = useState(-1);
  const [subtitleTracks, setSubtitleTracks] = useState<TrackOption[]>([]);
  const [currentSubtitle, setCurrentSubtitle] = useState(-1);
  const [reloadKey, setReloadKey] = useState(0);
  const [nextDismissed, setNextDismissed] = useState(false);

  // Timeline for non-live
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const hideControlsTimer = useRef<NodeJS.Timeout | null>(null);

  const resetHideTimer = () => {
    setShowControls(true);
    if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
    hideControlsTimer.current = setTimeout(() => {
      if (!videoRef.current?.paused && !showDrawer && !showQualityMenu && !showTracksMenu) {
        setShowControls(false);
      }
    }, 4000);
  };

  const contentId = currentStream ? currentStream.episode?.id || currentStream.id : '';

  /** Persists the position of on-demand content (movies and episodes). */
  // Last known position: the <video> element is already gone when the player
  // unmounts, so closing the player saves from here.
  const posRef = useRef({ id: '', t: 0, d: 0 });
  const persistProgress = () => {
    const v = videoRef.current;
    if (v && posRef.current.id === contentId) {
      posRef.current.t = v.currentTime;
      if (Number.isFinite(v.duration)) posRef.current.d = v.duration;
    }
    const { id, t, d } = posRef.current;
    if (!id || t <= 0 || !(d > 0)) return;
    saveProgress(id, t, d);
  };

  const destroyEngines = () => {
    if (retryTimer.current) clearTimeout(retryTimer.current);
    if (hlsRef.current) {
      hlsRef.current.destroy();
      hlsRef.current = null;
    }
    if (tsRef.current) {
      try {
        tsRef.current.pause();
        tsRef.current.unload();
        tsRef.current.detachMediaElement();
        tsRef.current.destroy();
      } catch {
        /* already torn down */
      }
      tsRef.current = null;
    }
  };

  const fail = (message: string) => {
    setHasError(true);
    setErrorMessage(message);
    setIsBuffering(false);
  };

  /** Live streams drop often; retry quietly with backoff before showing an error. */
  const scheduleRetry = (message: string) => {
    if (retryRef.current >= MAX_AUTO_RETRIES) {
      fail(message);
      return;
    }
    const delay = Math.min(15000, 1000 * 2 ** retryRef.current);
    retryRef.current += 1;
    setIsBuffering(true);
    retryTimer.current = setTimeout(() => setReloadKey((k) => k + 1), delay);
  };

  // Initialize playback whenever the stream (or a reload) changes
  useEffect(() => {
    if (!currentStream || !isPlayerOpen) return;
    const video = videoRef.current;
    if (!video) return;

    let cancelled = false;
    // Same stream again means a reconnect (keep position); otherwise a fresh start.
    const isReload = startedStreamRef.current === currentStream;
    startedStreamRef.current = currentStream;
    setHasError(false);
    setIsBuffering(true);
    setAvailableLevels([]);
    setCurrentLevel(-1);
    setAudioTracks([]);
    setSubtitleTracks([]);
    setCurrentAudio(-1);
    setCurrentSubtitle(-1);
    setNextDismissed(false);
    destroyEngines();
    if (!isReload) posRef.current = { id: '', t: 0, d: 0 };
    video.removeAttribute('src');

    const streamUrl = currentStream.streamUrl;
    const isLive = currentStream.isLive;
    const engine = detectEngine(streamUrl, isLive);
    const startAt = !isReload ? currentStream.startPositionSeconds ?? 0 : posRef.current.t || currentStream.startPositionSeconds || 0;
    const bufferLen = bufferSeconds(settings.bufferMode);

    const seekToStart = () => {
      if (!isLive && startAt > 0 && video.duration > startAt) video.currentTime = startAt;
    };
    video.addEventListener('loadedmetadata', seekToStart, { once: true });

    const playSafe = () => {
      video.play().catch(() => setIsPlaying(false));
    };

    const startNative = () => {
      video.src = streamUrl;
      video.load();
      playSafe();
    };

    const startHls = async () => {
      const { default: Hls } = await import('hls.js');
      if (cancelled) return;
      if (!Hls.isSupported()) {
        // Safari and some TV browsers play HLS natively.
        if (video.canPlayType('application/vnd.apple.mpegurl')) startNative();
        else fail('Este navegador não reproduz HLS. Use o app Android ou outro navegador.');
        return;
      }
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: settings.bufferMode === 'low',
        maxBufferLength: bufferLen,
        backBufferLength: 30,
        startPosition: !isLive && startAt > 0 ? startAt : -1,
      });
      hlsRef.current = hls;
      hls.loadSource(streamUrl);
      hls.attachMedia(video);

      hls.on(Hls.Events.MANIFEST_PARSED, (_, data) => {
        retryRef.current = 0;
        setIsBuffering(false);
        playSafe();
        setAvailableLevels(data.levels.map((lvl, index) => ({ id: index, height: lvl.height, bitrate: lvl.bitrate })));
      });
      hls.on(Hls.Events.LEVEL_SWITCHED, (_, data) => setCurrentLevel(data.level));
      hls.on(Hls.Events.AUDIO_TRACKS_UPDATED, (_, data) => {
        setAudioTracks(data.audioTracks.map((t, i) => ({ id: i, label: t.name || t.lang || `Áudio ${i + 1}` })));
        setCurrentAudio(hls.audioTrack);
      });
      hls.on(Hls.Events.SUBTITLE_TRACKS_UPDATED, (_, data) => {
        setSubtitleTracks(data.subtitleTracks.map((t, i) => ({ id: i, label: t.name || t.lang || `Legenda ${i + 1}` })));
      });
      hls.on(Hls.Events.ERROR, (_, data) => {
        if (!data.fatal) return;
        if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
          hls.recoverMediaError();
        } else if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
          scheduleRetry('Não foi possível conectar ao servidor do canal. Ele pode estar fora do ar.');
        } else {
          fail('Falha ao decodificar a transmissão. No Android, ative o player nativo em Configurações.');
        }
      });
    };

    const startTs = async () => {
      const { default: mpegts } = await import('mpegts.js');
      if (cancelled) return;
      if (!mpegts.isSupported()) {
        fail('Este aparelho não reproduz MPEG-TS no navegador. Use o app Android (player nativo).');
        return;
      }
      const player = mpegts.createPlayer(
        { type: 'mpegts', isLive, url: streamUrl },
        {
          enableWorker: true,
          liveBufferLatencyChasing: settings.bufferMode === 'low',
          lazyLoad: !isLive,
          autoCleanupSourceBuffer: true,
        }
      );
      tsRef.current = player;
      player.attachMediaElement(video);
      player.on(mpegts.Events.ERROR, (type: string) => {
        if (type === mpegts.ErrorTypes.NETWORK_ERROR) scheduleRetry('Não foi possível conectar ao servidor do canal.');
        else fail('Formato de vídeo não suportado pelo navegador. Use o app Android (player nativo).');
      });
      player.on(mpegts.Events.MEDIA_INFO, () => {
        retryRef.current = 0;
      });
      player.load();
      Promise.resolve(player.play()).catch(() => setIsPlaying(false));
    };

    if (engine === 'hls') void startHls();
    else if (engine === 'mpegts') void startTs();
    else startNative();

    resetHideTimer();

    return () => {
      cancelled = true;
      video.removeEventListener('loadedmetadata', seekToStart);
      persistProgress();
      destroyEngines();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentStream, isPlayerOpen, reloadKey]);

  // New stream: forget retries from the previous one.
  useEffect(() => {
    retryRef.current = 0;
  }, [currentStream]);

  // Closing and reopening the same stream object must start fresh too.
  useEffect(() => {
    if (!isPlayerOpen) startedStreamRef.current = null;
  }, [isPlayerOpen]);

  // Video event listeners
  const onTimeUpdate = () => {
    const v = videoRef.current;
    if (!v) return;
    if (currentStream && !currentStream.isLive) {
      posRef.current = { id: contentId, t: v.currentTime, d: Number.isFinite(v.duration) ? v.duration : 0 };
    }
    setCurrentTime(v.currentTime);
    setDuration(Number.isFinite(v.duration) ? v.duration : 0);
    const now = Date.now();
    if (now - lastSavedRef.current > 10_000) {
      lastSavedRef.current = now;
      persistProgress();
    }
  };

  const onEnded = () => {
    persistProgress();
    if (currentStream?.episode && settings.autoplayNextEpisode && playNextEpisode()) return;
    if (!currentStream?.isLive) closePlayer();
  };

  const onWaiting = () => setIsBuffering(true);
  const onPlaying = () => {
    setIsBuffering(false);
    setIsPlaying(true);
  };
  const onError = () => {
    // hls.js / mpegts.js report their own errors; this covers plain files.
    if (hlsRef.current || tsRef.current) return;
    if (currentStream?.isLive) scheduleRetry('Erro ao reproduzir a transmissão.');
    else fail('Não foi possível abrir este vídeo. O formato pode não ser suportado pelo navegador (use o app Android) ou o link expirou.');
  };

  const selectAudio = (id: number) => {
    if (hlsRef.current) hlsRef.current.audioTrack = id;
    setCurrentAudio(id);
    setShowTracksMenu(false);
  };

  const selectSubtitle = (id: number) => {
    if (hlsRef.current) {
      hlsRef.current.subtitleTrack = id;
      hlsRef.current.subtitleDisplay = id >= 0;
    }
    setCurrentSubtitle(id);
    setShowTracksMenu(false);
  };

  const manualReconnect = () => {
    retryRef.current = 0;
    setHasError(false);
    setReloadKey((k) => k + 1);
  };

  // Keyboard navigation shortcuts
  useEffect(() => {
    if (!isPlayerOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) {
        return;
      }

      resetHideTimer();
      if (e.key === ' ' || e.key === 'k') {
        e.preventDefault();
        togglePlay();
      } else if (e.key === 'm') {
        toggleMute();
      } else if (e.key === 'f') {
        toggleFullscreen();
      } else if (e.key === 'Escape') {
        if (showDrawer) {
          setShowDrawer(false);
        } else if (showTracksMenu || showQualityMenu) {
          setShowTracksMenu(false);
          setShowQualityMenu(false);
        } else if (isFullscreen) {
          document.exitFullscreen?.();
        } else {
          closePlayer();
        }
      } else if (e.key === 'ArrowRight' && !currentStream?.isLive) {
        if (videoRef.current) videoRef.current.currentTime += 10;
      } else if (e.key === 'ArrowLeft' && !currentStream?.isLive) {
        if (videoRef.current) videoRef.current.currentTime -= 10;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isPlayerOpen, isPlaying, isMuted, isFullscreen, showDrawer, showTracksMenu, showQualityMenu, currentStream]);

  if (!isPlayerOpen || !currentStream) return null;

  const nextTitle = currentStream.episode ? getNextEpisodeTitle() : null;
  // Zapping list: the current channel's category, capped so the drawer opens instantly.
  const drawerGroup = currentStream.channel?.groupTitle;
  const drawerChannels = (drawerGroup ? filteredChannels.filter((c) => c.groupTitle === drawerGroup) : filteredChannels).slice(0, 300);
  const showNextCard = !!nextTitle && !nextDismissed && duration > 0 && duration - currentTime <= NEXT_EPISODE_LEAD_SECONDS;

  const togglePlay = () => {
    if (!videoRef.current) return;
    if (videoRef.current.paused) {
      videoRef.current.play();
      setIsPlaying(true);
    } else {
      videoRef.current.pause();
      setIsPlaying(false);
    }
  };

  const toggleMute = () => {
    if (!videoRef.current) return;
    const nextMuted = !isMuted;
    videoRef.current.muted = nextMuted;
    setIsMuted(nextMuted);
  };

  const handleVolumeChange = (newVol: number) => {
    if (!videoRef.current) return;
    videoRef.current.volume = newVol;
    setVolume(newVol);
    if (newVol > 0 && isMuted) {
      videoRef.current.muted = false;
      setIsMuted(false);
    }
  };

  const toggleFullscreen = () => {
    if (!containerRef.current) return;
    if (!document.fullscreenElement) {
      containerRef.current.requestFullscreen().then(() => setIsFullscreen(true)).catch(() => {});
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false)).catch(() => {});
    }
  };

  const togglePiP = async () => {
    if (!videoRef.current) return;
    try {
      if (document.pictureInPictureElement) {
        await document.exitPictureInPicture();
      } else {
        await videoRef.current.requestPictureInPicture();
      }
    } catch (e) {
      console.warn('PiP not supported or failed', e);
    }
  };

  const selectQuality = (levelIndex: number) => {
    if (hlsRef.current) {
      hlsRef.current.currentLevel = levelIndex;
      setCurrentLevel(levelIndex);
      setShowQualityMenu(false);
    }
  };

  const cycleAspectRatio = () => {
    const modes: ('fit' | 'fill' | '16:9' | '4:3')[] = ['fit', 'fill', '16:9', '4:3'];
    const next = modes[(modes.indexOf(aspectRatio) + 1) % modes.length];
    setAspectRatio(next);
  };

  const formatSeconds = (sec: number) => {
    if (isNaN(sec) || sec <= 0) return '00:00';
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <div
      ref={containerRef}
      onMouseMove={resetHideTimer}
      className="fixed inset-0 z-50 bg-black flex items-center justify-center overflow-hidden select-none font-sans"
    >
      {/* Video Element */}
      <video
        ref={videoRef}
        playsInline
        autoPlay
        onTimeUpdate={onTimeUpdate}
        onEnded={onEnded}
        onWaiting={onWaiting}
        onPlaying={onPlaying}
        onError={onError}
        onClick={togglePlay}
        className={`w-full h-full transition-all duration-300 ${
          aspectRatio === 'fit'
            ? 'object-contain'
            : aspectRatio === 'fill'
            ? 'object-cover'
            : aspectRatio === '16:9'
            ? 'aspect-video object-cover'
            : 'aspect-[4/3] object-cover'
        }`}
      />

      {/* Buffering Indicator */}
      {isBuffering && !hasError && (
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none bg-black/40 backdrop-blur-[2px]">
          <div className="relative w-16 h-16">
            <div className="absolute inset-0 rounded-full border-4 border-[#7C5CFF]/20 animate-pulse" />
            <div className="absolute inset-0 rounded-full border-4 border-t-[#22D3A6] border-r-[#7C5CFF] border-b-transparent border-l-transparent animate-spin" />
          </div>
          <span className="mt-4 text-xs font-semibold tracking-wider uppercase text-[#F5F5F7]/80">
            Conectando ao sinal...
          </span>
        </div>
      )}

      {/* Error Overlay */}
      {hasError && (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#060608]/90 p-6 text-center z-30">
          <div className="w-16 h-16 rounded-full bg-[#FF5468]/20 flex items-center justify-center mb-4 text-[#FF5468]">
            <Radio className="w-8 h-8 animate-pulse" />
          </div>
          <h3 className="text-xl font-bold text-white mb-2">Erro de Reprodução</h3>
          <p className="text-sm text-[#A1A1AA] max-w-md mb-6">{errorMessage}</p>
          <div className="flex items-center gap-3">
            <button
              onClick={manualReconnect}
              autoFocus
              data-tv-title="Tentar reconectar"
              className="px-5 py-2.5 rounded-xl bg-[#7C5CFF] hover:bg-[#7C5CFF]/80 text-white font-medium flex items-center gap-2 cursor-pointer transition-colors"
            >
              <RotateCcw className="w-4 h-4" /> Tentar Reconectar
            </button>
            <button
              onClick={closePlayer}
              className="px-5 py-2.5 rounded-xl bg-[#141418] hover:bg-[#2A2A31] text-[#A1A1AA] hover:text-white font-medium cursor-pointer transition-colors"
            >
              Fechar Player
            </button>
          </div>
        </div>
      )}

      {/* Top Bar Overlay */}
      <div
        className={`absolute top-0 left-0 right-0 p-6 bg-gradient-to-b from-black/85 via-black/40 to-transparent transition-opacity duration-300 z-20 flex items-center justify-between ${
          showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
      >
        <div className="flex items-center gap-4">
          <button
            onClick={closePlayer}
            tabIndex={0}
            data-tv-title="Voltar ao Catálogo"
            className="tv-card w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-md flex items-center justify-center text-white transition-all cursor-pointer focus:outline-none"
            title="Voltar (Esc)"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
          {currentStream.logoUrl && (
            <img
              src={currentStream.logoUrl}
              alt={currentStream.title}
              className="w-10 h-10 object-contain rounded-lg bg-black/40 p-1 border border-white/10"
              onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
            />
          )}
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-bold text-white tracking-wide">{currentStream.title}</h2>
              {currentStream.isLive && (
                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-[#22D3A6]/20 text-[#22D3A6] text-xs font-bold uppercase tracking-wider border border-[#22D3A6]/30">
                  <span className="w-2 h-2 rounded-full bg-[#22D3A6] animate-ping" />
                  Ao Vivo
                </span>
              )}
            </div>
            {currentStream.subtitle && (
              <p className="text-xs text-[#A1A1AA] line-clamp-1">{currentStream.subtitle}</p>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          {currentStream.channel && (
            <button
              onClick={() => toggleFavorite(currentStream.channel!.id)}
              tabIndex={0}
              data-tv-title="Favoritar Canal"
              className={`tv-card w-10 h-10 rounded-xl backdrop-blur-md flex items-center justify-center transition-all cursor-pointer focus:outline-none ${
                isFavorite(currentStream.channel.id)
                  ? 'bg-[#FF6F91]/20 text-[#FF6F91] border border-[#FF6F91]/40'
                  : 'bg-white/10 hover:bg-white/20 text-white'
              }`}
              title="Favoritar Canal"
            >
              <Heart
                className="w-5 h-5"
                fill={isFavorite(currentStream.channel.id) ? '#FF6F91' : 'none'}
              />
            </button>
          )}

          <button
            onClick={() => setShowDrawer(!showDrawer)}
            tabIndex={0}
            data-tv-title="Zapping: Lista de Canais"
            className="tv-card px-3.5 py-2 rounded-xl bg-white/10 hover:bg-white/20 backdrop-blur-md text-white text-xs font-semibold flex items-center gap-2 transition-all cursor-pointer focus:outline-none"
          >
            <List className="w-4 h-4 text-[#22D3A6]" />
            Canais
          </button>

          <button
            onClick={closePlayer}
            tabIndex={0}
            data-tv-title="Fechar Player"
            className="tv-card w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-md flex items-center justify-center text-white transition-all cursor-pointer focus:outline-none"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Bottom Controls Overlay */}
      <div
        className={`absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/90 via-black/50 to-transparent transition-opacity duration-300 z-20 ${
          showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
      >
        {/* Progress Bar for VOD */}
        {!currentStream.isLive && duration > 0 && (
          <div className="mb-4">
            <div className="relative group/bar flex items-center">
              <input
                type="range"
                min={0}
                max={duration}
                value={currentTime}
                onChange={(e) => {
                  const val = parseFloat(e.target.value);
                  if (videoRef.current) videoRef.current.currentTime = val;
                  setCurrentTime(val);
                }}
                className="w-full h-1.5 bg-white/20 rounded-lg appearance-none cursor-pointer accent-[#7C5CFF] hover:h-2.5 transition-all"
              />
            </div>
            <div className="flex justify-between text-xs text-[#A1A1AA] mt-1.5 font-mono">
              <span>{formatSeconds(currentTime)}</span>
              <span>{formatSeconds(duration)}</span>
            </div>
          </div>
        )}

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            {/* Play/Pause Button */}
            <button
              onClick={togglePlay}
              tabIndex={0}
              data-tv-title={isPlaying ? 'Pausar Reprodução' : 'Continuar Reprodução'}
              className="tv-card w-12 h-12 rounded-xl bg-[#7C5CFF] hover:bg-[#7C5CFF]/80 text-white flex items-center justify-center transition-all transform active:scale-95 shadow-lg shadow-[#7C5CFF]/30 cursor-pointer focus:outline-none"
            >
              {isPlaying ? <Pause className="w-6 h-6 fill-current" /> : <Play className="w-6 h-6 fill-current ml-0.5" />}
            </button>

            {/* Volume Control */}
            <div className="flex items-center gap-2 group/vol">
              <button
                onClick={toggleMute}
                tabIndex={0}
                data-tv-title={isMuted || volume === 0 ? 'Desmutar Áudio' : 'Mutar Áudio'}
                className="tv-card w-10 h-10 rounded-lg hover:bg-white/10 text-white flex items-center justify-center transition-colors cursor-pointer focus:outline-none"
              >
                {isMuted || volume === 0 ? (
                  <VolumeX className="w-5 h-5 text-[#FF5468]" />
                ) : (
                  <Volume2 className="w-5 h-5 text-white" />
                )}
              </button>
              <input
                type="range"
                min={0}
                max={1}
                step={0.05}
                value={isMuted ? 0 : volume}
                onChange={(e) => handleVolumeChange(parseFloat(e.target.value))}
                className="w-20 md:w-28 h-1 bg-white/20 rounded appearance-none accent-[#22D3A6] cursor-pointer"
              />
            </div>

            {currentStream.isLive && (
              <div className="hidden sm:flex items-center gap-2 pl-2 border-l border-white/10 text-xs text-[#A1A1AA]">
                <Radio className="w-4 h-4 text-[#22D3A6]" />
                <span>Stream Contínuo</span>
              </div>
            )}
          </div>

          <div className="flex items-center gap-2">
            {/* Aspect Ratio Toggle */}
            <button
              onClick={cycleAspectRatio}
              tabIndex={0}
              data-tv-title={`Proporção: ${aspectRatio}`}
              className="tv-card px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs text-white font-medium uppercase tracking-wider backdrop-blur cursor-pointer focus:outline-none"
              title="Ajustar Proporção"
            >
              {aspectRatio}
            </button>

            {/* Quality Menu Toggle */}
            {availableLevels.length > 0 && (
              <div className="relative">
                <button
                  onClick={() => setShowQualityMenu(!showQualityMenu)}
                  tabIndex={0}
                  data-tv-title="Qualidade da Transmissão"
                  className="tv-card w-10 h-10 rounded-lg hover:bg-white/10 text-white flex items-center justify-center transition-colors cursor-pointer focus:outline-none"
                  title="Qualidade do Stream"
                >
                  <Sliders className="w-5 h-5" />
                </button>
                {showQualityMenu && (
                  <div className="absolute bottom-12 right-0 bg-[#141418] border border-[#2A2A31] rounded-xl shadow-2xl p-2 min-w-[160px] z-50">
                    <p className="text-[11px] font-semibold text-[#A1A1AA] uppercase px-3 py-1.5">
                      Qualidade
                    </p>
                    <button
                      onClick={() => selectQuality(-1)}
                      tabIndex={0}
                      data-tv-title="Qualidade Automática"
                      className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#7C5CFF]/20 rounded-lg flex items-center justify-between focus:outline-none"
                    >
                      <span>Automático</span>
                      {currentLevel === -1 && <Check className="w-3.5 h-3.5 text-[#22D3A6]" />}
                    </button>
                    {availableLevels.map((lvl) => (
                      <button
                        key={lvl.id}
                        onClick={() => selectQuality(lvl.id)}
                        tabIndex={0}
                        data-tv-title={`Resolução ${lvl.height}p`}
                        className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#7C5CFF]/20 rounded-lg flex items-center justify-between focus:outline-none"
                      >
                        <span>{lvl.height}p ({Math.round(lvl.bitrate / 1000)}k)</span>
                        {currentLevel === lvl.id && <Check className="w-3.5 h-3.5 text-[#22D3A6]" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* Audio & subtitle tracks */}
            {(audioTracks.length > 1 || subtitleTracks.length > 0) && (
              <div className="relative">
                <button
                  onClick={() => setShowTracksMenu(!showTracksMenu)}
                  data-tv-title="Áudio e legendas"
                  className="tv-card w-10 h-10 rounded-lg hover:bg-white/10 text-white flex items-center justify-center transition-colors cursor-pointer focus:outline-none"
                  title="Áudio e legendas"
                >
                  <Languages className="w-5 h-5" />
                </button>
                {showTracksMenu && (
                  <div className="absolute bottom-12 right-0 bg-[#141418] border border-[#2A2A31] rounded-xl shadow-2xl p-2 min-w-[200px] max-h-[60vh] overflow-y-auto z-50">
                    {audioTracks.length > 1 && (
                      <>
                        <p className="text-[11px] font-semibold text-[#A1A1AA] uppercase px-3 py-1.5">Áudio</p>
                        {audioTracks.map((t) => (
                          <button
                            key={`a${t.id}`}
                            onClick={() => selectAudio(t.id)}
                            data-tv-title={`Áudio: ${t.label}`}
                            className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#7C5CFF]/20 rounded-lg flex items-center justify-between focus:outline-none"
                          >
                            <span>{t.label}</span>
                            {currentAudio === t.id && <Check className="w-3.5 h-3.5 text-[#22D3A6]" />}
                          </button>
                        ))}
                      </>
                    )}
                    {subtitleTracks.length > 0 && (
                      <>
                        <p className="text-[11px] font-semibold text-[#A1A1AA] uppercase px-3 py-1.5">Legendas</p>
                        {[{ id: -1, label: 'Desligadas' }, ...subtitleTracks].map((t) => (
                          <button
                            key={`s${t.id}`}
                            onClick={() => selectSubtitle(t.id)}
                            data-tv-title={`Legenda: ${t.label}`}
                            className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#7C5CFF]/20 rounded-lg flex items-center justify-between focus:outline-none"
                          >
                            <span>{t.label}</span>
                            {currentSubtitle === t.id && <Check className="w-3.5 h-3.5 text-[#22D3A6]" />}
                          </button>
                        ))}
                      </>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* Picture in Picture */}
            <button
              onClick={togglePiP}
              tabIndex={0}
              data-tv-title="Modo Picture-in-Picture"
              className="tv-card w-10 h-10 rounded-lg hover:bg-white/10 text-white flex items-center justify-center transition-colors cursor-pointer focus:outline-none"
              title="Picture-in-Picture"
            >
              <PictureInPicture className="w-5 h-5" />
            </button>

            {/* Fullscreen */}
            <button
              onClick={toggleFullscreen}
              tabIndex={0}
              data-tv-title="Tela Cheia"
              className="tv-card w-10 h-10 rounded-lg hover:bg-white/10 text-white flex items-center justify-center transition-colors cursor-pointer focus:outline-none"
              title="Tela Cheia (F)"
            >
              {isFullscreen ? <Minimize className="w-5 h-5" /> : <Maximize className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>

      {/* Next episode card */}
      {showNextCard && (
        <div className="absolute right-8 bottom-32 z-30 bg-[#141418]/95 border border-[#2A2A31] rounded-2xl p-4 shadow-2xl max-w-xs space-y-3">
          <p className="text-[11px] uppercase font-bold text-[#A1A1AA]">Próximo episódio</p>
          <p className="text-sm font-bold text-white line-clamp-2">{nextTitle}</p>
          {settings.autoplayNextEpisode && (
            <p className="text-xs text-[#22D3A6]">Começa em {Math.max(0, Math.ceil(duration - currentTime))} s</p>
          )}
          <div className="flex gap-2">
            <button
              onClick={() => playNextEpisode()}
              autoFocus
              data-tv-title="Assistir próximo episódio"
              className="tv-card px-4 py-2 rounded-xl bg-white text-[#060608] text-xs font-bold flex items-center gap-1.5 cursor-pointer focus:outline-none"
            >
              <SkipForward className="w-4 h-4" /> Assistir
            </button>
            <button
              onClick={() => setNextDismissed(true)}
              data-tv-title="Continuar neste episódio"
              className="tv-card px-4 py-2 rounded-xl bg-white/10 text-white text-xs font-semibold cursor-pointer focus:outline-none"
            >
              Ficar
            </button>
          </div>
        </div>
      )}

      {/* Quick Channel Drawer */}
      {showDrawer && (
        <div className="quick-drawer absolute top-0 right-0 bottom-0 w-80 md:w-96 bg-[#060608]/95 backdrop-blur-xl border-l border-[#2A2A31] z-40 flex flex-col shadow-2xl animate-in slide-in-from-right duration-200">
          <div className="p-4 border-b border-[#2A2A31] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Tv className="w-5 h-5 text-[#7C5CFF]" />
              <h3 className="font-bold text-white text-base">Zapping Rápido de Canais</h3>
            </div>
            <button
              onClick={() => setShowDrawer(false)}
              tabIndex={0}
              data-tv-title="Fechar Lista de Canais"
              className="tv-card w-8 h-8 rounded-lg hover:bg-[#141418] text-[#A1A1AA] hover:text-white flex items-center justify-center cursor-pointer focus:outline-none"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {drawerChannels.length > 0 ? (
              drawerChannels.map((ch, idx) => {
                const isSelected = currentStream.channel?.id === ch.id;
                return (
                  <div
                    key={ch.id}
                    tabIndex={0}
                    data-tv-title={`Zapping: ${ch.name}`}
                    onClick={() => {
                      playChannel(ch);
                      setShowDrawer(false);
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        playChannel(ch);
                        setShowDrawer(false);
                      }
                    }}
                    className={`tv-card p-3 rounded-xl flex items-center gap-3 cursor-pointer transition-all border focus:outline-none ${
                      isSelected
                        ? 'bg-[#7C5CFF]/30 border-[#7C5CFF] text-white shadow-lg'
                        : 'bg-[#141418]/60 hover:bg-[#141418] border-[#2A2A31]/40 text-[#A1A1AA] hover:text-white'
                    }`}
                  >
                    <span className="text-xs font-mono font-bold text-[#A1A1AA] w-6 text-center">
                      {(idx + 1).toString().padStart(2, '0')}
                    </span>
                    {ch.logoUrl ? (
                      <img
                        src={ch.logoUrl}
                        alt={ch.name}
                        className="w-9 h-9 object-contain rounded-md bg-black/40 p-1"
                        onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
                      />
                    ) : (
                      <div className="w-9 h-9 rounded-md bg-[#2A2A31] flex items-center justify-center text-white">
                        <Tv className="w-4 h-4" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate text-white">{ch.name}</p>
                      <p className="text-[11px] text-[#A1A1AA]">{ch.groupTitle || 'Geral'}</p>
                    </div>
                    {ch.resolution && (
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-black/40 text-[#22D3A6] border border-[#22D3A6]/30">
                        {ch.resolution}
                      </span>
                    )}
                  </div>
                );
              })
            ) : (
              <div className="py-12 text-center text-[#A1A1AA] text-xs">
                Nenhum canal ativo disponível nesta lista.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
