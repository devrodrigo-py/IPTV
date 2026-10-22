import { Channel } from '../types';

export interface M3uParseResult {
  channels: Channel[];
  totalLines: number;
  validCount: number;
  errorCount: number;
}

/**
 * Robust parser for M3U and M3U8 playlists matching Flutter specification.
 * Supports EXTINF format with varying attribute positions, missing attributes,
 * group-title, tvg-id, tvg-name, tvg-logo, and direct URLs.
 */
export function parseM3u(content: string, playlistId: string): M3uParseResult {
  const lines = content.split(/\r?\n/);
  const channels: Channel[] = [];
  let errorCount = 0;

  let pendingExtinf: string | null = null;

  for (let i = 0; i < lines.length; i++) {
    const rawLine = lines[i].trim();
    if (!rawLine) continue;
    if (rawLine.startsWith('#EXTM3U')) continue;

    if (rawLine.startsWith('#EXTINF:')) {
      pendingExtinf = rawLine;
      continue;
    }

    if (rawLine.startsWith('#')) {
      // Other directive or comment, ignore
      continue;
    }

    // Likely a stream URL
    if (pendingExtinf) {
      const channel = parseExtinfLine(pendingExtinf, rawLine, playlistId, channels.length + 1);
      if (channel) {
        channels.push(channel);
      } else {
        errorCount++;
      }
      pendingExtinf = null;
    } else {
      // Stream URL without preceding EXTINF
      if (isValidStreamUrl(rawLine)) {
        const name = extractNameFromUrl(rawLine);
        channels.push({
          id: `ch_${playlistId}_${channels.length + 1}`,
          playlistId,
          name,
          streamUrl: rawLine,
          groupTitle: 'Geral',
          resolution: 'HD',
        });
      }
    }
  }

  return {
    channels,
    totalLines: lines.length,
    validCount: channels.length,
    errorCount,
  };
}

function parseExtinfLine(extinf: string, url: string, playlistId: string, index: number): Channel | null {
  if (!isValidStreamUrl(url)) return null;

  // Extract channel name after the last comma
  const commaIdx = extinf.indexOf(',');
  const name = commaIdx !== -1 ? extinf.substring(commaIdx + 1).trim() : extractNameFromUrl(url);

  // Extract attributes: tvg-id, tvg-name, tvg-logo, group-title
  const tvgId = extractAttribute(extinf, 'tvg-id');
  const tvgName = extractAttribute(extinf, 'tvg-name');
  const logoUrl = extractAttribute(extinf, 'tvg-logo') || extractAttribute(extinf, 'logo');
  const groupTitle = extractAttribute(extinf, 'group-title') || extractAttribute(extinf, 'group') || 'Geral';

  // Guess resolution from name or url
  let resolution: '4K' | 'FHD' | 'HD' | 'SD' = 'HD';
  const nameUpper = name.toUpperCase();
  if (nameUpper.includes('4K') || nameUpper.includes('UHD')) {
    resolution = '4K';
  } else if (nameUpper.includes('FHD') || nameUpper.includes('1080')) {
    resolution = 'FHD';
  } else if (nameUpper.includes('HD') || nameUpper.includes('720')) {
    resolution = 'HD';
  } else if (nameUpper.includes('SD') || nameUpper.includes('480')) {
    resolution = 'SD';
  }

  return {
    id: `ch_${playlistId}_${index}`,
    sourceId: tvgId || undefined,
    playlistId,
    name: name || `Canal ${index}`,
    streamUrl: url,
    logoUrl: logoUrl || undefined,
    groupTitle,
    tvgId: tvgId || undefined,
    tvgName: tvgName || undefined,
    resolution,
  };
}

function extractAttribute(line: string, attr: string): string | null {
  const regex = new RegExp(`${attr}="([^"]*)"`, 'i');
  const match = line.match(regex);
  if (match && match[1]) return match[1];

  // Try unquoted attribute
  const regexUnquoted = new RegExp(`${attr}=([^\\s,]+)`, 'i');
  const matchUnquoted = line.match(regexUnquoted);
  if (matchUnquoted && matchUnquoted[1]) return matchUnquoted[1];

  return null;
}

function isValidStreamUrl(url: string): boolean {
  return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('rtsp://');
}

function extractNameFromUrl(url: string): string {
  try {
    const parts = url.split('/');
    const last = parts[parts.length - 1];
    return decodeURIComponent(last.split('?')[0].replace(/\.[^/.]+$/, '')) || 'Stream Sem Título';
  } catch {
    return 'Stream';
  }
}
