import { Channel, EpgProgram } from '../types';

/** Keep programs from 3h ago to 36h ahead; older or further data only costs memory. */
export function trimEpgWindow(programs: EpgProgram[], now: number = Date.now(), pastMs = 3 * 3600_000, futureMs = 36 * 3600_000): EpgProgram[] {
  const from = now - pastMs;
  const to = now + futureMs;
  return programs.filter((p) => {
    const end = Date.parse(p.endUtc);
    const start = Date.parse(p.startUtc);
    return end >= from && start <= to;
  });
}

/** Programs grouped per EPG channel key, sorted by start time. */
export type EpgIndex = Map<string, EpgProgram[]>;

export function buildEpgIndex(programs: EpgProgram[]): EpgIndex {
  const idx: EpgIndex = new Map();
  for (const p of programs) {
    const list = idx.get(p.channelId);
    if (list) list.push(p);
    else idx.set(p.channelId, [p]);
  }
  for (const list of idx.values()) list.sort((a, b) => (a.startUtc < b.startUtc ? -1 : a.startUtc > b.startUtc ? 1 : 0));
  return idx;
}

/** EPG keys a channel can match: XMLTV id (tvg-id), the app id, and tvg-name. */
export function epgKeysFor(channel: Pick<Channel, 'id' | 'tvgId' | 'tvgName'>): string[] {
  const keys = [channel.tvgId, channel.id, channel.tvgName].filter((k): k is string => !!k);
  return Array.from(new Set(keys));
}

export function programsFor(index: EpgIndex, channel: Pick<Channel, 'id' | 'tvgId' | 'tvgName'>): EpgProgram[] {
  for (const key of epgKeysFor(channel)) {
    const list = index.get(key);
    if (list && list.length) return list;
  }
  return [];
}

export function currentProgram(list: EpgProgram[], now: number = Date.now()): EpgProgram | undefined {
  // Lists are short (a day per channel); a linear scan from the end is fine.
  for (let i = list.length - 1; i >= 0; i--) {
    const p = list[i];
    if (Date.parse(p.startUtc) <= now) {
      return Date.parse(p.endUtc) >= now ? p : undefined;
    }
  }
  return undefined;
}

/** Drops programs whose channel is not in the user's lists to keep the store small. */
export function keepKnownChannels(programs: EpgProgram[], channels: Channel[]): EpgProgram[] {
  const known = new Set<string>();
  for (const c of channels) for (const k of epgKeysFor(c)) known.add(k);
  return programs.filter((p) => known.has(p.channelId));
}
