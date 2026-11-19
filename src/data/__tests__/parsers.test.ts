import { describe, expect, it } from 'vitest';
import { parseM3u } from '../m3uParser';
import { classifyM3u } from '../m3uClassify';
import { parseXmltv, parseXmltvTime } from '../xmltvParser';
import { buildEpgIndex, currentProgram, keepKnownChannels, programsFor, trimEpgWindow } from '../epg';

const M3U = `#EXTM3U url-tvg="http://epg.example/guide.xml.gz,http://alt"
#EXTINF:-1 tvg-id="globo.br" tvg-logo="http://l/g.png" group-title="Abertos",Globo HD
http://s.example/live/u/p/1.ts
#EXTINF:-1 group-title="Filmes Ação",Duna (2021)
http://s.example/movie/u/p/77.mkv
#EXTINF:-1 group-title="Séries",Dark S01 E02 Mentiras
http://s.example/series/u/p/501.mp4
#EXTINF:-1 group-title="Séries",Dark S01E01
http://s.example/series/u/p/500.mp4
#EXTINF:-1,Sem URL valida
not-a-url
http://bare.example/stream.m3u8
`;

describe('m3u', () => {
  it('parses header epg url and entries', () => {
    const r = parseM3u(M3U, 'p');
    expect(r.epgUrl).toBe('http://epg.example/guide.xml.gz');
    expect(r.channels).toHaveLength(5);
    expect(r.channels[0]).toMatchObject({ name: 'Globo HD', tvgId: 'globo.br', groupTitle: 'Abertos', logoUrl: 'http://l/g.png' });
    expect(r.errorCount).toBe(1);
  });

  it('splits live, movies and series episodes', () => {
    const { channels, vod, series } = classifyM3u(parseM3u(M3U, 'p').channels, 'p');
    expect(channels.map((c) => c.name)).toEqual(['Globo HD', 'stream']);
    expect(vod[0]).toMatchObject({ title: 'Duna', year: 2021, category: 'Filmes Ação' });
    expect(series).toHaveLength(1);
    expect(series[0].title).toBe('Dark');
    expect(series[0].seasons[0].episodes.map((e) => [e.episodeNumber, e.title])).toEqual([
      [1, 'Episódio 1'],
      [2, 'Mentiras'],
    ]);
  });
});

const XML = `<?xml version="1.0"?><tv>
<channel id="globo.br"><display-name>Globo</display-name></channel>
<programme channel="globo.br" start="20261119120000 -0300" stop="20261119130000 -0300"><title lang="pt">Jornal &amp; Cia</title><desc>Not&#237;cias</desc></programme>
<programme start="20261119130000 -0300" stop="20261119140000 -0300" channel="globo.br"><title><![CDATA[Novela]]></title></programme>
<programme start="20261119130000" stop="20261119140000" channel="other"><title>X</title></programme>
</tv>`;

describe('xmltv', () => {
  it('parses times with offsets', () => {
    expect(parseXmltvTime('20261119120000 -0300')?.toISOString()).toBe('2026-11-19T15:00:00.000Z');
    expect(parseXmltvTime('garbage')).toBeNull();
  });

  it('parses programmes regardless of attribute order and decodes entities', () => {
    const r = parseXmltv(XML);
    expect(r.channels['globo.br']).toBe('Globo');
    expect(r.programs).toHaveLength(3);
    expect(r.programs[0]).toMatchObject({ title: 'Jornal & Cia', description: 'Notícias', channelId: 'globo.br' });
    expect(r.programs[1].title).toBe('Novela');
  });

  it('indexes, trims and resolves the current programme by tvg-id', () => {
    const progs = parseXmltv(XML).programs;
    const now = Date.parse('2026-11-19T15:30:00Z');
    const kept = keepKnownChannels(trimEpgWindow(progs, now), [{ id: 'ch_1', tvgId: 'globo.br', playlistId: 'p', name: 'G', streamUrl: 'u' }]);
    expect(kept).toHaveLength(2);
    const idx = buildEpgIndex(kept);
    const list = programsFor(idx, { id: 'ch_1', tvgId: 'globo.br' });
    expect(currentProgram(list, now)?.title).toBe('Jornal & Cia');
    expect(currentProgram(list, Date.parse('2026-11-19T20:00:00Z'))).toBeUndefined();
    expect(trimEpgWindow(progs, Date.parse('2026-12-30T00:00:00Z'))).toEqual([]);
  });
});
