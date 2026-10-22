import React, { useEffect, useRef, useState } from 'react';
import Hls from 'hls.js';
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
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

export const VideoPlayer: React.FC = () => {
  const { currentStream, isPlayerOpen, closePlayer, filteredChannels, playChannel, isFavorite, toggleFavorite } = useApp();

  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hlsRef = useRef<Hls | null>(null);

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
  const [availableLevels, setAvailableLevels] = useState<{ id: number; height: number; bitrate: number }[]>([]);
  const [currentLevel, setCurrentLevel] = useState<number>(-1); // -1 is auto

  // Timeline for non-live
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const hideControlsTimer = useRef<NodeJS.Timeout | null>(null);

  const resetHideTimer = () => {
    setShowControls(true);
    if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
    hideControlsTimer.current = setTimeout(() => {
      if (isPlaying && !showDrawer && !showQualityMenu) {
        setShowControls(false);
      }
    }, 4000);
  };

  // Initialize playback whenever currentStream changes
  useEffect(() => {
    if (!currentStream || !isPlayerOpen) return;

    const video = videoRef.current;
    if (!video) return;

    setHasError(false);
    setIsBuffering(true);
    setAvailableLevels([]);
    setCurrentLevel(-1);

    if (hlsRef.current) {
      hlsRef.current.destroy();
      hlsRef.current = null;
    }

    const streamUrl = currentStream.streamUrl;
    const isHlsUrl = streamUrl.includes('.m3u8') || streamUrl.includes('/hls/') || streamUrl.includes('live');

    if (Hls.isSupported() && isHlsUrl) {
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
        backBufferLength: 60,
      });
      hlsRef.current = hls;

      hls.loadSource(streamUrl);
      hls.attachMedia(video);

      hls.on(Hls.Events.MANIFEST_PARSED, (_, data) => {
        setIsBuffering(false);
        video.play().catch(() => setIsPlaying(false));
        const levels = data.levels.map((lvl, index) => ({
          id: index,
          height: lvl.height,
          bitrate: lvl.bitrate,
        }));
        setAvailableLevels(levels);
      });

      hls.on(Hls.Events.LEVEL_SWITCHED, (_, data) => {
        setCurrentLevel(data.level);
      });

      hls.on(Hls.Events.ERROR, (_, data) => {
        console.warn('HLS Event Error:', data);
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              hls.startLoad();
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              hls.recoverMediaError();
              break;
            default:
              setHasError(true);
              setErrorMessage('Falha na conexão do stream. O servidor de origem pode estar temporariamente offline.');
              setIsBuffering(false);
              hls.destroy();
              break;
          }
        }
      });
    } else {
      // Native MP4 or Native HLS in Safari
      video.src = streamUrl;
      video.load();
      video.play().catch(() => setIsPlaying(false));
    }

    resetHideTimer();

    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy();
        hlsRef.current = null;
      }
    };
  }, [currentStream, isPlayerOpen]);

  // Video event listeners
  const onTimeUpdate = () => {
    if (videoRef.current) {
      setCurrentTime(videoRef.current.currentTime);
      setDuration(videoRef.current.duration || 0);
    }
  };

  const onWaiting = () => setIsBuffering(true);
  const onPlaying = () => {
    setIsBuffering(false);
    setIsPlaying(true);
  };
  const onError = () => {
    setIsBuffering(false);
    setHasError(true);
    setErrorMessage('Erro ao reproduzir o vídeo. Verifique se a URL da transmissão está ativa.');
  };

  // Keyboard navigation shortcuts
  useEffect(() => {
    if (!isPlayerOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // Guard: do not trigger player shortcuts if typing in form inputs or dialogs
      const target = e.target as HTMLElement | null;
      if (
        target &&
        (target.tagName === 'INPUT' ||
          target.tagName === 'TEXTAREA' ||
          target.isContentEditable)
      ) {
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
  }, [isPlayerOpen, isPlaying, isMuted, isFullscreen, showDrawer, currentStream]);

  if (!isPlayerOpen || !currentStream) return null;

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
            <div className="absolute inset-0 rounded-full border-4 border-[#6B4FE0]/20 animate-pulse" />
            <div className="absolute inset-0 rounded-full border-4 border-t-[#1FCFAE] border-r-[#6B4FE0] border-b-transparent border-l-transparent animate-spin" />
          </div>
          <span className="mt-4 text-xs font-semibold tracking-wider uppercase text-[#F5F3FF]/80">
            Conectando ao sinal...
          </span>
        </div>
      )}

      {/* Error Overlay */}
      {hasError && (
        <div className="absolute inset-0 flex flex-col items-center justify-center bg-[#07070F]/90 p-6 text-center z-30">
          <div className="w-16 h-16 rounded-full bg-[#FF5468]/20 flex items-center justify-center mb-4 text-[#FF5468]">
            <Radio className="w-8 h-8 animate-pulse" />
          </div>
          <h3 className="text-xl font-bold text-white mb-2">Erro de Reprodução</h3>
          <p className="text-sm text-[#A8A6C0] max-w-md mb-6">{errorMessage}</p>
          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                setHasError(false);
                setIsBuffering(true);
                if (videoRef.current) {
                  videoRef.current.load();
                  videoRef.current.play().catch(() => {});
                }
              }}
              className="px-5 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-medium flex items-center gap-2 cursor-pointer transition-colors"
            >
              <RotateCcw className="w-4 h-4" /> Tentar Reconectar
            </button>
            <button
              onClick={closePlayer}
              className="px-5 py-2.5 rounded-xl bg-[#16162A] hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white font-medium cursor-pointer transition-colors"
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
                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-[#1FCFAE]/20 text-[#1FCFAE] text-xs font-bold uppercase tracking-wider border border-[#1FCFAE]/30">
                  <span className="w-2 h-2 rounded-full bg-[#1FCFAE] animate-ping" />
                  Ao Vivo
                </span>
              )}
            </div>
            {currentStream.subtitle && (
              <p className="text-xs text-[#A8A6C0] line-clamp-1">{currentStream.subtitle}</p>
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
            <List className="w-4 h-4 text-[#1FCFAE]" />
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
                className="w-full h-1.5 bg-white/20 rounded-lg appearance-none cursor-pointer accent-[#6B4FE0] hover:h-2.5 transition-all"
              />
            </div>
            <div className="flex justify-between text-xs text-[#A8A6C0] mt-1.5 font-mono">
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
              className="tv-card w-12 h-12 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white flex items-center justify-center transition-all transform active:scale-95 shadow-lg shadow-[#6B4FE0]/30 cursor-pointer focus:outline-none"
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
                className="w-20 md:w-28 h-1 bg-white/20 rounded appearance-none accent-[#1FCFAE] cursor-pointer"
              />
            </div>

            {currentStream.isLive && (
              <div className="hidden sm:flex items-center gap-2 pl-2 border-l border-white/10 text-xs text-[#A8A6C0]">
                <Radio className="w-4 h-4 text-[#1FCFAE]" />
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
                  <div className="absolute bottom-12 right-0 bg-[#16162A] border border-[#2A2A45] rounded-xl shadow-2xl p-2 min-w-[160px] z-50">
                    <p className="text-[11px] font-semibold text-[#A8A6C0] uppercase px-3 py-1.5">
                      Qualidade
                    </p>
                    <button
                      onClick={() => selectQuality(-1)}
                      tabIndex={0}
                      data-tv-title="Qualidade Automática"
                      className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#6B4FE0]/20 rounded-lg flex items-center justify-between focus:outline-none"
                    >
                      <span>Automático</span>
                      {currentLevel === -1 && <Check className="w-3.5 h-3.5 text-[#1FCFAE]" />}
                    </button>
                    {availableLevels.map((lvl) => (
                      <button
                        key={lvl.id}
                        onClick={() => selectQuality(lvl.id)}
                        tabIndex={0}
                        data-tv-title={`Resolução ${lvl.height}p`}
                        className="tv-card w-full px-3 py-2 text-left text-xs text-white hover:bg-[#6B4FE0]/20 rounded-lg flex items-center justify-between focus:outline-none"
                      >
                        <span>{lvl.height}p ({Math.round(lvl.bitrate / 1000)}k)</span>
                        {currentLevel === lvl.id && <Check className="w-3.5 h-3.5 text-[#1FCFAE]" />}
                      </button>
                    ))}
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

      {/* Quick Channel Drawer */}
      {showDrawer && (
        <div className="quick-drawer absolute top-0 right-0 bottom-0 w-80 md:w-96 bg-[#07070F]/95 backdrop-blur-xl border-l border-[#2A2A45] z-40 flex flex-col shadow-2xl animate-in slide-in-from-right duration-200">
          <div className="p-4 border-b border-[#2A2A45] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Tv className="w-5 h-5 text-[#6B4FE0]" />
              <h3 className="font-bold text-white text-base">Zapping Rápido de Canais</h3>
            </div>
            <button
              onClick={() => setShowDrawer(false)}
              tabIndex={0}
              data-tv-title="Fechar Lista de Canais"
              className="tv-card w-8 h-8 rounded-lg hover:bg-[#16162A] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer focus:outline-none"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-3 space-y-2">
            {filteredChannels.length > 0 ? (
              filteredChannels.map((ch, idx) => {
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
                        playChannel(ch);
                        setShowDrawer(false);
                      }
                    }}
                    className={`tv-card p-3 rounded-xl flex items-center gap-3 cursor-pointer transition-all border focus:outline-none ${
                      isSelected
                        ? 'bg-[#6B4FE0]/30 border-[#6B4FE0] text-white shadow-lg'
                        : 'bg-[#16162A]/60 hover:bg-[#16162A] border-[#2A2A45]/40 text-[#A8A6C0] hover:text-white'
                    }`}
                  >
                    <span className="text-xs font-mono font-bold text-[#A8A6C0] w-6 text-center">
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
                      <div className="w-9 h-9 rounded-md bg-[#2A2A45] flex items-center justify-center text-white">
                        <Tv className="w-4 h-4" />
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold truncate text-white">{ch.name}</p>
                      <p className="text-[11px] text-[#A8A6C0]">{ch.groupTitle || 'Geral'}</p>
                    </div>
                    {ch.resolution && (
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-black/40 text-[#1FCFAE] border border-[#1FCFAE]/30">
                        {ch.resolution}
                      </span>
                    )}
                  </div>
                );
              })
            ) : (
              <div className="py-12 text-center text-[#A8A6C0] text-xs">
                Nenhum canal ativo disponível nesta lista.
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
