import 'fake-indexeddb/auto';
import { describe, expect, it } from 'vitest';
import { detectDeviceProfile } from '../../platform/platform';
import { applyProxy } from '../../platform/http';
import { cleanSearchTitle } from '../tmdb';
import { createDebouncedWriter, dbDelete, dbGet, dbSet } from '../db';

describe('device profile', () => {
  it('detects Fire TV sticks as low-end TVs', () => {
    const p = detectDeviceProfile('Mozilla/5.0 (Linux; Android 9; AFTMM Build/PS7633) AppleWebKit', 1, 4);
    expect(p).toMatchObject({ isFireTv: true, isAndroidTv: true, isLowEnd: true, maxMultiviewTiles: 2 });
  });
  it('detects Xiaomi boxes and desktop', () => {
    expect(detectDeviceProfile('Mozilla/5.0 (Linux; Android 11; MIBOX4) AppleWebKit', 2, 4).isAndroidTv).toBe(true);
    const desk = detectDeviceProfile('Mozilla/5.0 (X11; Linux x86_64) Chrome/130', 8, 8);
    expect(desk).toMatchObject({ isAndroidTv: false, isLowEnd: false, maxMultiviewTiles: 9 });
  });
});

describe('http proxy', () => {
  it('appends or substitutes the encoded url', () => {
    expect(applyProxy('http://a/b?c=1', '')).toBe('http://a/b?c=1');
    expect(applyProxy('http://a/b?c=1', 'https://p/?url=')).toBe('https://p/?url=http%3A%2F%2Fa%2Fb%3Fc%3D1');
    expect(applyProxy('http://a', 'https://p/{url}/x')).toBe('https://p/http%3A%2F%2Fa/x');
  });
});

describe('tmdb title cleanup', () => {
  it('removes provider tags', () => {
    expect(cleanSearchTitle('PT-BR | Duna (2021) [4K] DUBLADO')).toEqual({ title: 'Duna', year: 2021 });
    expect(cleanSearchTitle('The.Office.US')).toEqual({ title: 'The Office US', year: undefined });
  });
});

describe('indexeddb store', () => {
  it('stores large arrays and deletes', async () => {
    const big = Array.from({ length: 20000 }, (_, i) => ({ id: `ch_${i}`, name: `Canal ${i}`, streamUrl: `http://x/${i}.ts` }));
    await dbSet('channels', big);
    expect((await dbGet<typeof big>('channels'))?.length).toBe(20000);
    await dbDelete('channels');
    expect(await dbGet('channels')).toBeUndefined();
  });
  it('debounces writes and flushes the latest value', async () => {
    const w = createDebouncedWriter(10_000);
    w.write('k', 1);
    w.write('k', 2);
    await w.flushAll();
    expect(await dbGet('k')).toBe(2);
  });
});
