import { registerPlugin } from '@capacitor/core';
import { isNativeApp } from './platform';

/**
 * Bridge to the Android Media3/ExoPlayer activity (android/.../NebulaPlayerPlugin.java).
 * The native player decodes what the WebView cannot: MPEG-TS, HEVC, AC3/EAC3
 * passthrough, embedded subtitles and multiple audio tracks.
 */

export interface NativeQueueItem {
  id: string;
  title: string;
  url: string;
  logoUrl?: string;
  subtitle?: string;
}

export interface NativePlayOptions {
  url: string;
  title: string;
  subtitle?: string;
  isLive: boolean;
  startPositionMs?: number;
  /** For live TV: channel list so D-pad up/down and CH+/CH- can zap natively. */
  queue?: NativeQueueItem[];
  queueIndex?: number;
  userAgent?: string;
  /** Buffer profile chosen in Settings. */
  bufferMode?: 'low' | 'balanced' | 'high';
  /** For episodes: label of the next episode to offer near the end. */
  nextTitle?: string;
}

export interface NativePlayResult {
  positionMs: number;
  durationMs: number;
  completed: boolean;
  /** Index of the channel playing when the user left (after zapping). */
  queueIndex: number;
  /** True when the user chose "Próximo episódio". */
  playNext: boolean;
  error?: string;
}

interface NebulaPlayerPlugin {
  play(options: NativePlayOptions): Promise<NativePlayResult>;
  isVoiceSearchAvailable(): Promise<{ available: boolean }>;
  voiceSearch(): Promise<{ text: string }>;
}

const NebulaPlayer = registerPlugin<NebulaPlayerPlugin>('NebulaPlayer');

export function canUseNativePlayer(): boolean {
  return isNativeApp();
}

export function playNative(options: NativePlayOptions): Promise<NativePlayResult> {
  return NebulaPlayer.play(options);
}

/** Speech recognition through the TV's system service (Google TV / Android TV). */
export async function isVoiceSearchAvailable(): Promise<boolean> {
  if (!isNativeApp()) return false;
  try {
    return (await NebulaPlayer.isVoiceSearchAvailable()).available;
  } catch {
    return false;
  }
}

export async function voiceSearch(): Promise<string> {
  const res = await NebulaPlayer.voiceSearch();
  return res.text?.trim() ?? '';
}
