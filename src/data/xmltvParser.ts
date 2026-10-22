import { EpgProgram } from '../types';

export interface XmltvParseResult {
  channels: Record<string, string>; // channel id -> display name
  programs: EpgProgram[];
  errorCount: number;
}

/**
 * Robust XMLTV parser that extracts channel schedules and normalizes
 * all program timestamps to ISO UTC strings.
 */
export function parseXmltv(content: string): XmltvParseResult {
  const channels: Record<string, string> = {};
  const programs: EpgProgram[] = [];
  let errorCount = 0;

  try {
    // Extract channels
    const channelRegex = /<channel\s+id="([^"]+)"[^>]*>[\s\S]*?<display-name[^>]*>([\s\S]*?)<\/display-name>[\s\S]*?<\/channel>/gi;
    let chMatch;
    while ((chMatch = channelRegex.exec(content)) !== null) {
      const id = chMatch[1];
      const name = decodeXml(chMatch[2].trim());
      channels[id] = name;
    }

    // Extract programmes
    const programmeRegex = /<programme\s+start="([^"]+)"\s+stop="([^"]+)"\s+channel="([^"]+)"[^>]*>([\s\S]*?)<\/programme>/gi;
    let progMatch;
    let idx = 0;

    while ((progMatch = programmeRegex.exec(content)) !== null) {
      try {
        const startStr = progMatch[1];
        const stopStr = progMatch[2];
        const channelId = progMatch[3];
        const body = progMatch[4];

        const startUtc = parseXmltvTime(startStr);
        const endUtc = parseXmltvTime(stopStr);

        if (!startUtc || !endUtc) {
          errorCount++;
          continue;
        }

        const title = extractTag(body, 'title');
        if (!title) {
          errorCount++;
          continue;
        }

        const description = extractTag(body, 'desc');
        const category = extractTag(body, 'category');
        const iconMatch = body.match(/<icon\s+src="([^"]+)"/i);
        const iconUrl = iconMatch ? iconMatch[1] : undefined;

        idx++;
        programs.push({
          id: `epg_${channelId}_${idx}`,
          channelId,
          title,
          description: description || undefined,
          startUtc: startUtc.toISOString(),
          endUtc: endUtc.toISOString(),
          category: category || undefined,
          iconUrl,
        });
      } catch {
        errorCount++;
      }
    }
  } catch (err) {
    console.error('Error parsing XMLTV:', err);
  }

  return { channels, programs, errorCount };
}

function extractTag(xml: string, tag: string): string | null {
  const regex = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i');
  const match = xml.match(regex);
  return match ? decodeXml(match[1].trim()) : null;
}

function decodeXml(str: string): string {
  return str
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

/**
 * Parses XMLTV format: YYYYMMDDhhmmss [+/-HHMM]
 * e.g. "20261022080000 +0000" or "20261022120000 -0300"
 */
export function parseXmltvTime(dateStr: string): Date | null {
  const clean = dateStr.trim();
  const match = clean.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(?:\s*([+-]\d{4}))?$/);
  if (!match) return null;

  const [_, y, m, d, h, min, s, tz] = match;
  let iso = `${y}-${m}-${d}T${h}:${min}:${s}`;

  if (tz) {
    const tzSign = tz[0];
    const tzH = tz.substring(1, 3);
    const tzM = tz.substring(3, 5);
    iso += `${tzSign}${tzH}:${tzM}`;
  } else {
    iso += 'Z';
  }

  const date = new Date(iso);
  return isNaN(date.getTime()) ? null : date;
}
