import { Channel, EpgProgram, Episode, Season, SeriesItem, VodItem } from '../types';
import { httpGetJson } from '../platform/http';

/**
 * Xtream Codes "player_api.php" client.
 *
 * Providers return loosely typed JSON (numbers as strings, nulls, arrays vs
 * objects), so every mapper below is defensive.
 */

export interface XtreamCredentials {
  baseUrl: string;
  username: string;
  password: string;
}

export interface XtreamAccount {
  status: string;
  expiresAt?: string; // ISO
  maxConnections?: number;
  activeConnections?: number;
  allowedOutputFormats: string[];
}

type Json = Record<string, unknown>;

export function normalizeBaseUrl(raw: string): string {
  let url = raw.trim();
  if (!/^https?:\/\//i.test(url)) url = `http://${url}`;
  url = url.replace(/\/+$/, '');
  url = url.replace(/\/(player_api|get|xmltv)\.php.*$/i, '');
  return url;
}

function q(creds: XtreamCredentials, params: Record<string, string> = {}): string {
  const search = new URLSearchParams({ username: creds.username, password: creds.password, ...params });
  return `${normalizeBaseUrl(creds.baseUrl)}/player_api.php?${search.toString()}`;
}

const str = (v: unknown): string => (v === null || v === undefined ? '' : String(v)).trim();
const num = (v: unknown): number => {
  const n = typeof v === 'number' ? v : parseFloat(str(v));
  return Number.isFinite(n) ? n : 0;
};
const firstString = (v: unknown): string => (Array.isArray(v) ? str(v[0]) : str(v));
const asArray = (v: unknown): Json[] => (Array.isArray(v) ? (v as Json[]) : []);

function seg(v: string): string {
  return encodeURIComponent(v);
}

export function liveStreamUrl(creds: XtreamCredentials, streamId: string, ext: 'ts' | 'm3u8'): string {
  return `${normalizeBaseUrl(creds.baseUrl)}/live/${seg(creds.username)}/${seg(creds.password)}/${streamId}.${ext}`;
}

export function vodStreamUrl(creds: XtreamCredentials, streamId: string, ext: string): string {
  return `${normalizeBaseUrl(creds.baseUrl)}/movie/${seg(creds.username)}/${seg(creds.password)}/${streamId}.${ext || 'mp4'}`;
}

export function episodeStreamUrl(creds: XtreamCredentials, episodeId: string, ext: string): string {
  return `${normalizeBaseUrl(creds.baseUrl)}/series/${seg(creds.username)}/${seg(creds.password)}/${episodeId}.${ext || 'mp4'}`;
}

export function xmltvUrl(creds: XtreamCredentials): string {
  const search = new URLSearchParams({ username: creds.username, password: creds.password });
  return `${normalizeBaseUrl(creds.baseUrl)}/xmltv.php?${search.toString()}`;
}

function guessResolution(name: string): Channel['resolution'] {
  const n = name.toUpperCase();
  if (/\b(4K|UHD|2160P?)\b/.test(n)) return '4K';
  if (/\b(FHD|1080P?)\b/.test(n)) return 'FHD';
  if (/\b(SD|480P?)\b/.test(n)) return 'SD';
  return 'HD';
}

function yearFrom(...candidates: unknown[]): number {
  for (const c of candidates) {
    const m = str(c).match(/(19|20)\d{2}/);
    if (m) return parseInt(m[0], 10);
  }
  return 0;
}

function rating10(item: Json): number {
  const r = num(item.rating);
  if (r > 0) return Math.round(Math.min(10, r) * 10) / 10;
  const r5 = num(item.rating_5based);
  return r5 > 0 ? Math.round(r5 * 2 * 10) / 10 : 0;
}

export async function authenticate(creds: XtreamCredentials): Promise<XtreamAccount> {
  const data = await httpGetJson<Json>(q(creds));
  const info = (data?.user_info ?? {}) as Json;
  if (num(info.auth) !== 1) {
    throw new Error('Usuário ou senha inválidos para este servidor Xtream.');
  }
  const status = str(info.status) || 'Active';
  if (status.toLowerCase() !== 'active') {
    throw new Error(`Conta ${status}. Verifique sua assinatura com o provedor.`);
  }
  const exp = num(info.exp_date);
  const formats = Array.isArray(info.allowed_output_formats)
    ? (info.allowed_output_formats as unknown[]).map(str)
    : [];
  return {
    status,
    expiresAt: exp > 0 ? new Date(exp * 1000).toISOString() : undefined,
    maxConnections: num(info.max_connections) || undefined,
    activeConnections: num(info.active_cons) || undefined,
    allowedOutputFormats: formats,
  };
}

async function categoryMap(creds: XtreamCredentials, action: string): Promise<Map<string, string>> {
  const cats = asArray(await httpGetJson<unknown>(q(creds, { action })));
  return new Map(cats.map((c) => [str(c.category_id), str(c.category_name) || 'Geral']));
}

export function mapLiveStreams(
  rows: Json[],
  cats: Map<string, string>,
  creds: XtreamCredentials,
  playlistId: string,
  ext: 'ts' | 'm3u8'
): Channel[] {
  const out: Channel[] = [];
  for (const r of rows) {
    const id = str(r.stream_id);
    if (!id) continue;
    const name = str(r.name) || `Canal ${id}`;
    out.push({
      id: `ch_${playlistId}_${id}`,
      sourceId: id,
      playlistId,
      name,
      streamUrl: liveStreamUrl(creds, id, ext),
      logoUrl: str(r.stream_icon) || undefined,
      groupTitle: cats.get(str(r.category_id)) || 'Geral',
      tvgId: str(r.epg_channel_id) || undefined,
      resolution: guessResolution(name),
    });
  }
  return out;
}

export function mapVodStreams(rows: Json[], cats: Map<string, string>, creds: XtreamCredentials, playlistId: string): VodItem[] {
  const out: VodItem[] = [];
  for (const r of rows) {
    const id = str(r.stream_id);
    if (!id) continue;
    const title = str(r.name) || `Filme ${id}`;
    out.push({
      id: `vod_${playlistId}_${id}`,
      playlistId,
      sourceId: id,
      tmdbId: str(r.tmdb) || str(r.tmdb_id) || undefined,
      title,
      posterUrl: str(r.stream_icon),
      description: str(r.plot),
      year: yearFrom(r.year, r.releaseDate, title),
      rating: rating10(r),
      durationMinutes: 0,
      category: cats.get(str(r.category_id)) || 'Filmes',
      streamUrl: vodStreamUrl(creds, id, str(r.container_extension)),
      addedAt: num(r.added) || undefined,
    });
  }
  return out;
}

export function mapSeries(rows: Json[], cats: Map<string, string>, playlistId: string): SeriesItem[] {
  const out: SeriesItem[] = [];
  for (const r of rows) {
    const id = str(r.series_id);
    if (!id) continue;
    out.push({
      id: `ser_${playlistId}_${id}`,
      playlistId,
      sourceId: id,
      tmdbId: str(r.tmdb) || undefined,
      title: str(r.name) || `Série ${id}`,
      posterUrl: str(r.cover),
      backdropUrl: firstString(r.backdrop_path) || undefined,
      overview: str(r.plot),
      rating: rating10(r),
      year: yearFrom(r.releaseDate, r.release_date, r.year) || undefined,
      category: cats.get(str(r.category_id)) || 'Séries',
      addedAt: num(r.last_modified) || undefined,
      seasons: [],
      seasonsLoaded: false,
    });
  }
  return out;
}

export interface XtreamCatalog {
  account: XtreamAccount;
  channels: Channel[];
  vod: VodItem[];
  series: SeriesItem[];
  epgUrl: string;
}

/**
 * Downloads the full catalog. Live TV is required; VOD and series failures
 * are tolerated because many accounts are live-only.
 */
export async function fetchCatalog(
  creds: XtreamCredentials,
  playlistId: string,
  opts: { preferHls: boolean; onProgress?: (step: string) => void }
): Promise<XtreamCatalog> {
  opts.onProgress?.('Autenticando…');
  const account = await authenticate(creds);
  const formats = account.allowedOutputFormats;
  const canHls = formats.length === 0 || formats.includes('m3u8');
  const canTs = formats.length === 0 || formats.includes('ts');
  const ext: 'ts' | 'm3u8' = opts.preferHls ? (canHls ? 'm3u8' : 'ts') : canTs ? 'ts' : 'm3u8';

  opts.onProgress?.('Baixando canais ao vivo…');
  const [liveCats, liveRows] = await Promise.all([
    categoryMap(creds, 'get_live_categories'),
    httpGetJson<unknown>(q(creds, { action: 'get_live_streams' }), { timeoutMs: 120_000 }),
  ]);
  const channels = mapLiveStreams(asArray(liveRows), liveCats, creds, playlistId, ext);

  opts.onProgress?.('Baixando filmes…');
  let vod: VodItem[] = [];
  try {
    const [vodCats, vodRows] = await Promise.all([
      categoryMap(creds, 'get_vod_categories'),
      httpGetJson<unknown>(q(creds, { action: 'get_vod_streams' }), { timeoutMs: 120_000 }),
    ]);
    vod = mapVodStreams(asArray(vodRows), vodCats, creds, playlistId);
  } catch (e) {
    console.warn('Xtream: VOD indisponível', e);
  }

  opts.onProgress?.('Baixando séries…');
  let series: SeriesItem[] = [];
  try {
    const [serCats, serRows] = await Promise.all([
      categoryMap(creds, 'get_series_categories'),
      httpGetJson<unknown>(q(creds, { action: 'get_series' }), { timeoutMs: 120_000 }),
    ]);
    series = mapSeries(asArray(serRows), serCats, playlistId);
  } catch (e) {
    console.warn('Xtream: séries indisponíveis', e);
  }

  return { account, channels, vod, series, epgUrl: xmltvUrl(creds) };
}

/** Normalises the "episodes" field, which can be an object keyed by season or an array. */
export function mapSeriesInfo(data: Json, creds: XtreamCredentials, seriesId: string): { seasons: Season[]; info: Json } {
  const info = (data?.info ?? {}) as Json;
  const seasonMeta = new Map<number, Json>();
  for (const s of asArray(data?.seasons)) seasonMeta.set(num(s.season_number), s);

  const groups: Json[][] = [];
  const raw = data?.episodes;
  if (Array.isArray(raw)) {
    for (const g of raw) groups.push(Array.isArray(g) ? (g as Json[]) : [g as Json]);
  } else if (raw && typeof raw === 'object') {
    for (const g of Object.values(raw as Record<string, unknown>)) groups.push(asArray(g));
  }

  const bySeason = new Map<number, Episode[]>();
  for (const group of groups) {
    for (const ep of group) {
      const epId = str(ep.id);
      if (!epId) continue;
      const seasonNumber = num(ep.season) || 1;
      const epInfo = (ep.info ?? {}) as Json;
      const durationSecs = num(epInfo.duration_secs);
      const episode: Episode = {
        id: `ep_${seriesId}_${epId}`,
        episodeNumber: num(ep.episode_num) || (bySeason.get(seasonNumber)?.length ?? 0) + 1,
        title: str(ep.title) || `Episódio ${num(ep.episode_num)}`,
        overview: str(epInfo.plot),
        streamUrl: episodeStreamUrl(creds, epId, str(ep.container_extension)),
        durationMinutes: durationSecs ? Math.round(durationSecs / 60) : 0,
        stillUrl: str(epInfo.movie_image) || undefined,
      };
      const list = bySeason.get(seasonNumber) ?? [];
      list.push(episode);
      bySeason.set(seasonNumber, list);
    }
  }

  const seasons: Season[] = Array.from(bySeason.entries())
    .sort((a, b) => a[0] - b[0])
    .map(([n, eps]) => ({
      seasonNumber: n,
      title: str(seasonMeta.get(n)?.name) || `Temporada ${n}`,
      episodes: eps.sort((a, b) => a.episodeNumber - b.episodeNumber),
    }));
  return { seasons, info };
}

export async function fetchSeriesInfo(creds: XtreamCredentials, series: SeriesItem): Promise<SeriesItem> {
  if (!series.sourceId) return series;
  const data = await httpGetJson<Json>(q(creds, { action: 'get_series_info', series_id: series.sourceId }));
  const { seasons, info } = mapSeriesInfo(data, creds, series.sourceId);
  return {
    ...series,
    seasons,
    seasonsLoaded: true,
    overview: series.overview || str(info.plot),
    backdropUrl: series.backdropUrl || firstString(info.backdrop_path) || undefined,
    tmdbId: series.tmdbId || str(info.tmdb_id) || undefined,
  };
}

export async function fetchVodInfo(creds: XtreamCredentials, vod: VodItem): Promise<VodItem> {
  if (!vod.sourceId) return vod;
  const data = await httpGetJson<Json>(q(creds, { action: 'get_vod_info', vod_id: vod.sourceId }));
  const info = (data?.info ?? {}) as Json;
  const durationSecs = num(info.duration_secs);
  const cast = str(info.cast || info.actors);
  return {
    ...vod,
    description: vod.description || str(info.plot || info.description),
    backdropUrl: vod.backdropUrl || firstString(info.backdrop_path) || undefined,
    posterUrl: vod.posterUrl || str(info.movie_image || info.cover_big),
    durationMinutes: durationSecs ? Math.round(durationSecs / 60) : vod.durationMinutes,
    director: vod.director || str(info.director) || undefined,
    cast: vod.cast?.length ? vod.cast : cast ? cast.split(',').map((c) => c.trim()).filter(Boolean).slice(0, 8) : undefined,
    year: vod.year || yearFrom(info.releasedate, info.release_date),
    rating: vod.rating || rating10(info),
    tmdbId: vod.tmdbId || str(info.tmdb_id) || undefined,
  };
}

function decodeBase64Utf8(v: unknown): string {
  const s = str(v);
  if (!s) return '';
  try {
    const bin = atob(s);
    const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    return new TextDecoder().decode(bytes);
  } catch {
    return s;
  }
}

/** Short EPG for one channel; used when the full XMLTV is too big or missing. */
export async function fetchShortEpg(creds: XtreamCredentials, channel: Channel, limit = 6): Promise<EpgProgram[]> {
  if (!channel.sourceId) return [];
  const data = await httpGetJson<Json>(
    q(creds, { action: 'get_short_epg', stream_id: channel.sourceId, limit: String(limit) })
  );
  return asArray(data?.epg_listings)
    .map((p, i): EpgProgram | null => {
      const start = num(p.start_timestamp);
      const stop = num(p.stop_timestamp);
      if (!start || !stop) return null;
      return {
        id: `sepg_${channel.id}_${start}_${i}`,
        channelId: channel.id,
        title: decodeBase64Utf8(p.title) || 'Programa',
        description: decodeBase64Utf8(p.description) || undefined,
        startUtc: new Date(start * 1000).toISOString(),
        endUtc: new Date(stop * 1000).toISOString(),
      };
    })
    .filter((p): p is EpgProgram => p !== null);
}
