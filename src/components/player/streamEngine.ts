/**
 * Picks how the browser player should open a URL.
 * - hls: .m3u8 playlists (hls.js, or native HLS on Safari)
 * - mpegts: raw MPEG-TS, which is what Xtream live channels serve by default
 * - native: progressive files (mp4, webm, mkv…) the <video> element plays itself
 */
export type StreamEngine = 'hls' | 'mpegts' | 'native';

export function detectEngine(url: string, isLive: boolean): StreamEngine {
  let path = url;
  try {
    path = new URL(url).pathname;
  } catch {
    /* relative or malformed: inspect the raw string */
  }
  const p = path.toLowerCase();
  if (p.endsWith('.m3u8') || p.endsWith('.m3u') || p.includes('/hls/') || /[?&](type|output)=(m3u8|hls)/i.test(url)) return 'hls';
  if (p.endsWith('.ts') || /[?&](type|output)=(ts|mpegts)/i.test(url)) return 'mpegts';
  if (/\.(mp4|m4v|webm|mkv|mov|avi|mp3|aac)$/.test(p)) return 'native';
  // Xtream live URLs without extension (/live/user/pass/123) serve MPEG-TS.
  if (isLive && /\/live\/[^/]+\/[^/]+\/\d+$/.test(p)) return 'mpegts';
  return isLive ? 'hls' : 'native';
}

export function bufferSeconds(mode: 'low' | 'balanced' | 'high'): number {
  return mode === 'low' ? 8 : mode === 'high' ? 60 : 30;
}
