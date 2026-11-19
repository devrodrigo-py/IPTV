import { Channel, EpgProgram, SeriesItem, VodItem } from '../types';
import { parseM3u } from './m3uParser';
import { classifyM3u } from './m3uClassify';
import { parseXmltv } from './xmltvParser';
import { trimEpgWindow } from './epg';

export type ParseRequest =
  | { id: number; kind: 'm3u'; content: string; playlistId: string }
  | { id: number; kind: 'xmltv'; content: string };

export type ParseResponse =
  | { id: number; ok: true; kind: 'm3u'; channels: Channel[]; vod: VodItem[]; series: SeriesItem[]; epgUrl?: string }
  | { id: number; ok: true; kind: 'xmltv'; programs: EpgProgram[] }
  | { id: number; ok: false; error: string };

export interface M3uResult {
  channels: Channel[];
  vod: VodItem[];
  series: SeriesItem[];
  epgUrl?: string;
}

let worker: Worker | null = null;
let nextId = 1;
const pending = new Map<number, (r: ParseResponse) => void>();

function getWorker(): Worker | null {
  if (worker) return worker;
  if (typeof Worker === 'undefined') return null;
  try {
    worker = new Worker(new URL('./parse.worker.ts', import.meta.url));
    worker.onmessage = (ev: MessageEvent<ParseResponse>) => {
      const cb = pending.get(ev.data.id);
      pending.delete(ev.data.id);
      cb?.(ev.data);
    };
    worker.onerror = () => {
      // Fail every waiting request; callers fall back to the main thread.
      for (const [id, cb] of pending) cb({ id, ok: false, error: 'worker-crashed' });
      pending.clear();
      worker?.terminate();
      worker = null;
    };
    return worker;
  } catch {
    return null;
  }
}

type ParseInput = ParseRequest extends infer R ? (R extends ParseRequest ? Omit<R, 'id'> : never) : never;

function run(req: ParseInput): Promise<ParseResponse> {
  const w = getWorker();
  const id = nextId++;
  if (!w) return Promise.resolve(parseInline({ ...req, id } as ParseRequest));
  return new Promise((resolve) => {
    pending.set(id, (res) => (res.ok ? resolve(res) : resolve(parseInline({ ...req, id } as ParseRequest))));
    w.postMessage({ ...req, id });
  });
}

function parseInline(req: ParseRequest): ParseResponse {
  if (req.kind === 'm3u') {
    const parsed = parseM3u(req.content, req.playlistId);
    return { id: req.id, ok: true, kind: 'm3u', ...classifyM3u(parsed.channels, req.playlistId), epgUrl: parsed.epgUrl };
  }
  return { id: req.id, ok: true, kind: 'xmltv', programs: trimEpgWindow(parseXmltv(req.content).programs) };
}

export async function parseM3uAsync(content: string, playlistId: string): Promise<M3uResult> {
  const res = await run({ kind: 'm3u', content, playlistId });
  if (!res.ok || res.kind !== 'm3u') return { channels: [], vod: [], series: [] };
  return { channels: res.channels, vod: res.vod, series: res.series, epgUrl: res.epgUrl };
}

export async function parseXmltvAsync(content: string): Promise<EpgProgram[]> {
  const res = await run({ kind: 'xmltv', content });
  if (!res.ok || res.kind !== 'xmltv') return [];
  return res.programs;
}
