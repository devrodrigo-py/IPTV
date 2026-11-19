import { describe, expect, it } from 'vitest';
import { detectEngine } from '../streamEngine';

describe('detectEngine', () => {
  it('routes by container', () => {
    expect(detectEngine('https://cdn.x/live/master.m3u8', true)).toBe('hls');
    expect(detectEngine('http://srv:8080/live/u/p/123.ts', true)).toBe('mpegts');
    expect(detectEngine('http://srv:8080/live/u/p/123', true)).toBe('mpegts');
    expect(detectEngine('http://srv:8080/movie/u/p/9.mkv', false)).toBe('native');
    expect(detectEngine('http://srv/get.php?x=1&output=m3u8', true)).toBe('hls');
  });
  it('does not treat "live" in a hostname as HLS', () => {
    expect(detectEngine('https://livecdn.example/video.mp4', false)).toBe('native');
  });
});
