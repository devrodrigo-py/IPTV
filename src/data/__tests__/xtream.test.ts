import { describe, expect, it, vi, beforeEach } from 'vitest';

vi.mock('../../platform/http', () => ({ httpGetJson: vi.fn() }));
import { httpGetJson } from '../../platform/http';
import {
  authenticate,
  fetchCatalog,
  fetchSeriesInfo,
  fetchShortEpg,
  liveStreamUrl,
  mapSeriesInfo,
  normalizeBaseUrl,
  xmltvUrl,
} from '../xtream';

const creds = { baseUrl: 'provider.tv:8080/', username: 'joão', password: 'p@ss' };
const mocked = vi.mocked(httpGetJson);

function routes(table: Record<string, unknown>) {
  mocked.mockImplementation(async (url: string) => {
    const action = new URL(url).searchParams.get('action') ?? 'auth';
    if (!(action in table)) throw new Error(`unexpected ${action}`);
    const v = table[action];
    if (v instanceof Error) throw v;
    return v as never;
  });
}

const okAuth = { user_info: { auth: 1, status: 'Active', exp_date: '1893456000', allowed_output_formats: ['m3u8', 'ts'] } };

beforeEach(() => {
  mocked.mockReset();
});

describe('xtream urls', () => {
  it('normalizes base url', () => {
    expect(normalizeBaseUrl('provider.tv:8080/')).toBe('http://provider.tv:8080');
    expect(normalizeBaseUrl('https://x.tv/player_api.php?username=a')).toBe('https://x.tv');
  });
  it('encodes credentials in stream and guide urls', () => {
    expect(liveStreamUrl(creds, '12', 'ts')).toBe('http://provider.tv:8080/live/jo%C3%A3o/p%40ss/12.ts');
    expect(xmltvUrl(creds)).toContain('/xmltv.php?username=jo%C3%A3o&password=p%40ss');
  });
});

describe('authenticate', () => {
  it('rejects wrong credentials', async () => {
    routes({ auth: { user_info: { auth: 0 } } });
    await expect(authenticate(creds)).rejects.toThrow(/inválidos/);
  });
  it('rejects expired accounts', async () => {
    routes({ auth: { user_info: { auth: 1, status: 'Expired' } } });
    await expect(authenticate(creds)).rejects.toThrow(/Expired/);
  });
  it('returns expiry and formats', async () => {
    routes({ auth: okAuth });
    const acc = await authenticate(creds);
    expect(acc.expiresAt).toBe('2030-01-01T00:00:00.000Z');
    expect(acc.allowedOutputFormats).toEqual(['m3u8', 'ts']);
  });
});

describe('fetchCatalog', () => {
  it('maps live, vod and series with categories', async () => {
    routes({
      auth: okAuth,
      get_live_categories: [{ category_id: '1', category_name: 'Esportes' }],
      get_live_streams: [
        { stream_id: 10, name: 'Sport 4K', stream_icon: 'http://i/l.png', category_id: '1', epg_channel_id: 'sport.br' },
        { stream_id: null, name: 'broken' },
      ],
      get_vod_categories: [{ category_id: '5', category_name: 'Ação' }],
      get_vod_streams: [{ stream_id: '77', name: 'Filme X (2021)', rating: '7.8', category_id: '5', container_extension: 'mkv', added: '1700000000' }],
      get_series_categories: [{ category_id: '9', category_name: 'Drama' }],
      get_series: [{ series_id: 3, name: 'Série Y', cover: 'c.jpg', rating_5based: 4, category_id: '9', backdrop_path: ['b.jpg'] }],
    });
    const cat = await fetchCatalog(creds, 'pl1', { preferHls: true });
    expect(cat.channels).toHaveLength(1);
    expect(cat.channels[0]).toMatchObject({ name: 'Sport 4K', groupTitle: 'Esportes', tvgId: 'sport.br', resolution: '4K', sourceId: '10' });
    expect(cat.channels[0].streamUrl.endsWith('/10.m3u8')).toBe(true);
    expect(cat.vod[0]).toMatchObject({ title: 'Filme X (2021)', year: 2021, rating: 7.8, category: 'Ação', addedAt: 1700000000 });
    expect(cat.vod[0].streamUrl).toMatch(/\/movie\/.+\/77\.mkv$/);
    expect(cat.series[0]).toMatchObject({ title: 'Série Y', rating: 8, backdropUrl: 'b.jpg', seasonsLoaded: false });
  });

  it('uses ts for native playback and survives missing VOD', async () => {
    routes({
      auth: okAuth,
      get_live_categories: [],
      get_live_streams: [{ stream_id: 1, name: 'A' }],
      get_vod_categories: new Error('404'),
      get_vod_streams: new Error('404'),
      get_series_categories: [],
      get_series: [],
    });
    const cat = await fetchCatalog(creds, 'pl1', { preferHls: false });
    expect(cat.channels[0].streamUrl.endsWith('/1.ts')).toBe(true);
    expect(cat.vod).toEqual([]);
  });

  it('falls back to ts when the account disallows m3u8', async () => {
    routes({
      auth: { user_info: { ...okAuth.user_info, allowed_output_formats: ['ts'] } },
      get_live_categories: [],
      get_live_streams: [{ stream_id: 1, name: 'A' }],
      get_vod_categories: [], get_vod_streams: [], get_series_categories: [], get_series: [],
    });
    const cat = await fetchCatalog(creds, 'pl1', { preferHls: true });
    expect(cat.channels[0].streamUrl.endsWith('/1.ts')).toBe(true);
  });
});

describe('series info', () => {
  it('handles episodes keyed by season', () => {
    const { seasons } = mapSeriesInfo(
      {
        seasons: [{ season_number: 1, name: 'Primeira' }],
        episodes: {
          '2': [{ id: '201', episode_num: 1, season: 2, title: 'S2E1', container_extension: 'mp4' }],
          '1': [
            { id: '102', episode_num: 2, season: 1, title: 'B', info: { duration_secs: 1800 } },
            { id: '101', episode_num: 1, season: 1, title: 'A' },
          ],
        },
      },
      creds,
      '3'
    );
    expect(seasons.map((s) => s.title)).toEqual(['Primeira', 'Temporada 2']);
    expect(seasons[0].episodes.map((e) => e.title)).toEqual(['A', 'B']);
    expect(seasons[0].episodes[1].durationMinutes).toBe(30);
    expect(seasons[1].episodes[0].streamUrl).toMatch(/\/series\/.+\/201\.mp4$/);
  });

  it('handles episodes as array of arrays', () => {
    const { seasons } = mapSeriesInfo({ episodes: [[{ id: '1', episode_num: 1, season: 1 }]] }, creds, '3');
    expect(seasons[0].episodes).toHaveLength(1);
  });

  it('fetches lazily and marks loaded', async () => {
    routes({ get_series_info: { info: { plot: 'Sinopse' }, episodes: { '1': [{ id: '5', episode_num: 1, season: 1 }] } } });
    const s = await fetchSeriesInfo(creds, { id: 'ser_1', sourceId: '3', title: 'T', posterUrl: '', overview: '', rating: 0, category: 'D', seasons: [] });
    expect(s.seasonsLoaded).toBe(true);
    expect(s.overview).toBe('Sinopse');
    expect(s.seasons[0].episodes[0].id).toBe('ep_3_5');
  });
});

describe('short epg', () => {
  it('decodes base64 utf-8 titles', async () => {
    const b64 = Buffer.from('Notícias', 'utf8').toString('base64');
    routes({ get_short_epg: { epg_listings: [{ title: b64, description: '', start_timestamp: '1700000000', stop_timestamp: '1700003600' }] } });
    const progs = await fetchShortEpg(creds, { id: 'ch1', sourceId: '9', playlistId: 'p', name: 'x', streamUrl: 'u' });
    expect(progs[0].title).toBe('Notícias');
    expect(progs[0].channelId).toBe('ch1');
  });
});
