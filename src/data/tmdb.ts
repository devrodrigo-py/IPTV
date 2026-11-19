import { httpGetJson } from '../platform/http';
import { dbGet, dbSet } from './db';

/**
 * Optional TMDB enrichment. Providers often ship tiny or missing posters and
 * no backdrops; TMDB fills those in. Lookups run lazily (when a title is shown
 * in detail or in the hero) and are cached on the device.
 */

export interface TmdbMeta {
  tmdbId?: string;
  posterUrl?: string;
  backdropUrl?: string;
  overview?: string;
  rating?: number;
  year?: number;
  trailerYoutubeKey?: string;
}

const IMG = 'https://image.tmdb.org/t/p/';
const CACHE_KEY = 'tmdb_cache_v1';
let cache: Record<string, TmdbMeta | null> | null = null;
let saveTimer: ReturnType<typeof setTimeout> | null = null;

async function loadCache(): Promise<Record<string, TmdbMeta | null>> {
  if (cache) return cache;
  try {
    cache = (await dbGet<Record<string, TmdbMeta | null>>(CACHE_KEY)) ?? {};
  } catch {
    cache = {};
  }
  return cache;
}

function scheduleSave() {
  if (saveTimer) clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    if (cache) void dbSet(CACHE_KEY, cache).catch(() => undefined);
  }, 1000);
}

/** Strips provider noise: "PT-BR | Duna (2021) [4K]" -> "Duna". */
export function cleanSearchTitle(raw: string): { title: string; year?: number } {
  let t = raw;
  const yearMatch = t.match(/\b(19\d{2}|20\d{2})\b/);
  t = t.replace(/^[A-Z]{2,3}(-[A-Z]{2})?\s*[|:-]\s*/i, '');
  t = t.replace(/\[[^\]]*\]|\([^)]*\)/g, ' ');
  t = t.replace(/\b(4K|UHD|FHD|HD|SD|1080p|720p|2160p|HDR|DUB|DUBLADO|LEG|LEGENDADO|NACIONAL)\b/gi, ' ');
  t = t.replace(/\b(19\d{2}|20\d{2})\b/g, ' ');
  t = t.replace(/[._]/g, ' ').replace(/\s+/g, ' ').trim();
  return { title: t, year: yearMatch ? parseInt(yearMatch[1], 10) : undefined };
}

function authFor(key: string): { query: string; headers?: Record<string, string> } {
  // v4 read tokens are long JWTs; v3 keys are 32 hex chars.
  if (key.length > 40) return { query: '', headers: { Authorization: `Bearer ${key}` } };
  return { query: `api_key=${encodeURIComponent(key)}&` };
}

interface SearchHit {
  id: number;
  poster_path?: string | null;
  backdrop_path?: string | null;
  overview?: string;
  vote_average?: number;
  release_date?: string;
  first_air_date?: string;
}

export async function lookupTmdb(
  apiKey: string,
  kind: 'movie' | 'tv',
  rawTitle: string,
  year?: number,
  language = 'pt-BR'
): Promise<TmdbMeta | null> {
  if (!apiKey || !rawTitle) return null;
  const { title, year: parsedYear } = cleanSearchTitle(rawTitle);
  const y = year || parsedYear;
  const cacheKey = `${kind}:${title.toLowerCase()}:${y ?? ''}:${language}`;
  const c = await loadCache();
  if (cacheKey in c) return c[cacheKey];

  const { query, headers } = authFor(apiKey);
  const yearParam = y ? `&${kind === 'movie' ? 'year' : 'first_air_date_year'}=${y}` : '';
  const url = `https://api.themoviedb.org/3/search/${kind}?${query}language=${language}&include_adult=false&query=${encodeURIComponent(title)}${yearParam}`;
  try {
    const res = await httpGetJson<{ results?: SearchHit[] }>(url, { headers, timeoutMs: 15_000 });
    const hit = res.results?.[0];
    const meta: TmdbMeta | null = hit
      ? {
          tmdbId: String(hit.id),
          posterUrl: hit.poster_path ? `${IMG}w342${hit.poster_path}` : undefined,
          backdropUrl: hit.backdrop_path ? `${IMG}w1280${hit.backdrop_path}` : undefined,
          overview: hit.overview || undefined,
          rating: hit.vote_average ? Math.round(hit.vote_average * 10) / 10 : undefined,
          year: parseInt((hit.release_date || hit.first_air_date || '').slice(0, 4), 10) || undefined,
        }
      : null;
    c[cacheKey] = meta;
    scheduleSave();
    return meta;
  } catch (e) {
    console.warn('TMDB lookup falhou', e);
    return null; // not cached: a network blip should not hide metadata forever
  }
}
