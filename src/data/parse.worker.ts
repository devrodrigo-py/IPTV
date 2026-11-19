/// <reference lib="webworker" />
import { parseM3u } from './m3uParser';
import { classifyM3u } from './m3uClassify';
import { parseXmltv } from './xmltvParser';
import { trimEpgWindow } from './epg';
import type { ParseRequest, ParseResponse } from './parseService';

/**
 * Off-main-thread parsing. A 50k-line M3U or a 40 MB XMLTV freezes a TV
 * stick's UI for seconds if parsed on the main thread.
 */
self.onmessage = (ev: MessageEvent<ParseRequest>) => {
  const req = ev.data;
  try {
    let res: ParseResponse;
    if (req.kind === 'm3u') {
      const parsed = parseM3u(req.content, req.playlistId);
      const classified = classifyM3u(parsed.channels, req.playlistId);
      res = { id: req.id, ok: true, kind: 'm3u', ...classified, epgUrl: parsed.epgUrl };
    } else {
      const parsed = parseXmltv(req.content);
      res = { id: req.id, ok: true, kind: 'xmltv', programs: trimEpgWindow(parsed.programs) };
    }
    (self as unknown as Worker).postMessage(res);
  } catch (e) {
    (self as unknown as Worker).postMessage({ id: req.id, ok: false, error: String((e as Error)?.message || e) });
  }
};
