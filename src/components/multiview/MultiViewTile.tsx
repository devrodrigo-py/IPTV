import React, { useEffect, useRef, useState } from 'react';
import { detectEngine } from '../player/streamEngine';
import { Volume2, VolumeX, RefreshCw, X, Radio, AlertCircle } from 'lucide-react';
import { Channel } from '../../types';

interface MultiViewTileProps {
  index: number;
  channel: Channel;
  isAudible: boolean;
  onToggleAudio: () => void;
  onChangeChannel: () => void;
  onRemoveChannel: () => void;
}

export const MultiViewTile: React.FC<MultiViewTileProps> = ({
  index,
  channel,
  isAudible,
  onToggleAudio,
  onChangeChannel,
  onRemoveChannel,
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  // Disposes whichever engine (hls.js or mpegts.js) the tile is using.
  const disposeRef = useRef<(() => void) | null>(null);

  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    let cancelled = false;

    setIsLoading(true);
    setHasError(false);
    disposeRef.current?.();
    disposeRef.current = null;

    const streamUrl = channel.streamUrl;
    const engine = detectEngine(streamUrl, true);
    const onFail = () => {
      setHasError(true);
      setIsLoading(false);
    };

    const start = async () => {
      if (engine === 'hls') {
        const { default: Hls } = await import('hls.js');
        if (cancelled) return;
        if (!Hls.isSupported()) {
          video.src = streamUrl;
          video.play().catch(() => {});
          return;
        }
        // Small buffers: several tiles decode at once.
        const hls = new Hls({ enableWorker: true, maxBufferLength: 10, backBufferLength: 10, capLevelToPlayerSize: true });
        disposeRef.current = () => hls.destroy();
        hls.loadSource(streamUrl);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, () => {
          setIsLoading(false);
          video.play().catch(() => {});
        });
        hls.on(Hls.Events.ERROR, (_, data) => {
          if (!data.fatal) return;
          if (data.type === Hls.ErrorTypes.NETWORK_ERROR) hls.startLoad();
          else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) hls.recoverMediaError();
          else onFail();
        });
      } else if (engine === 'mpegts') {
        const { default: mpegts } = await import('mpegts.js');
        if (cancelled) return;
        if (!mpegts.isSupported()) return onFail();
        const player = mpegts.createPlayer({ type: 'mpegts', isLive: true, url: streamUrl }, { enableWorker: true, autoCleanupSourceBuffer: true });
        disposeRef.current = () => {
          try {
            player.unload();
            player.detachMediaElement();
            player.destroy();
          } catch {
            /* already disposed */
          }
        };
        player.attachMediaElement(video);
        player.on(mpegts.Events.ERROR, onFail);
        player.load();
        Promise.resolve(player.play()).catch(() => {});
      } else {
        video.src = streamUrl;
        video.load();
        video.play().catch(() => {});
      }
    };
    void start();

    return () => {
      cancelled = true;
      disposeRef.current?.();
      disposeRef.current = null;
    };
  }, [channel.streamUrl]);

  // Sync mute state
  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.muted = !isAudible;
    }
  }, [isAudible]);

  return (
    <div
      className={`relative bg-[#07070F] rounded-2xl border overflow-hidden flex items-center justify-center group h-full w-full ${
        isAudible
          ? 'border-[#1FCFAE] shadow-lg shadow-[#1FCFAE]/20 ring-1 ring-[#1FCFAE]/50'
          : 'border-[#2A2A45]'
      }`}
    >
      <video
        ref={videoRef}
        autoPlay
        playsInline
        loop
        muted={!isAudible}
        onPlaying={() => setIsLoading(false)}
        onWaiting={() => setIsLoading(true)}
        onError={() => {
          setIsLoading(false);
          setHasError(true);
        }}
        className="w-full h-full object-cover"
      />

      {/* Loading overlay */}
      {isLoading && !hasError && (
        <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px] flex items-center justify-center pointer-events-none">
          <div className="w-8 h-8 rounded-full border-2 border-t-[#1FCFAE] border-r-[#6B4FE0] border-b-transparent border-l-transparent animate-spin" />
        </div>
      )}

      {/* Error overlay */}
      {hasError && (
        <div className="absolute inset-0 bg-[#07070F]/85 flex flex-col items-center justify-center p-3 text-center z-10">
          <AlertCircle className="w-6 h-6 text-[#FF5468] mb-1" />
          <span className="text-xs font-bold text-white">Sinal Indisponível</span>
          <button
            onClick={() => {
              setHasError(false);
              setIsLoading(true);
              videoRef.current?.load();
              videoRef.current?.play().catch(() => {});
            }}
            className="mt-2 px-2.5 py-1 rounded-lg bg-[#6B4FE0] text-[11px] font-semibold text-white flex items-center gap-1 cursor-pointer"
          >
            <RefreshCw className="w-3 h-3" /> Tentar Novamente
          </button>
        </div>
      )}

      {/* Top Overlay Controls */}
      <div className="absolute top-0 left-0 right-0 p-3 bg-gradient-to-b from-black/85 via-black/40 to-transparent flex items-center justify-between opacity-80 group-hover:opacity-100 transition-opacity z-20">
        <div className="flex items-center gap-2 min-w-0 pr-2">
          <span className="w-5 h-5 rounded-md bg-[#6B4FE0] text-white text-[10px] font-bold flex items-center justify-center shrink-0">
            {index + 1}
          </span>
          <span className="text-xs font-bold text-white truncate drop-shadow">
            {channel.name}
          </span>
        </div>

        <div className="flex items-center gap-1.5 shrink-0">
          {/* Audio focus button */}
          <button
            onClick={onToggleAudio}
            className={`w-7 h-7 rounded-lg flex items-center justify-center cursor-pointer transition-all ${
              isAudible
                ? 'bg-[#1FCFAE] text-black shadow-md font-bold'
                : 'bg-black/60 hover:bg-black/80 text-[#A8A6C0] hover:text-white'
            }`}
            title={isAudible ? 'Mutar Áudio' : 'Ouvir este canal'}
          >
            {isAudible ? <Volume2 className="w-3.5 h-3.5" /> : <VolumeX className="w-3.5 h-3.5" />}
          </button>

          {/* Change channel */}
          <button
            onClick={onChangeChannel}
            className="w-7 h-7 rounded-lg bg-black/60 hover:bg-black/80 text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer transition-colors"
            title="Trocar Canal"
          >
            <RefreshCw className="w-3.5 h-3.5" />
          </button>

          {/* Remove channel */}
          <button
            onClick={onRemoveChannel}
            className="w-7 h-7 rounded-lg bg-black/60 hover:bg-[#FF5468] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer transition-colors"
            title="Remover Canal"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
};
