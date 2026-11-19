import { CapacitorHttp } from '@capacitor/core';
import { isNativeApp } from './platform';

/**
 * Network access for playlists, provider APIs and EPG.
 *
 * Most IPTV servers do not send CORS headers, so a browser `fetch` is blocked.
 * - In the Android app requests go through the native HTTP stack (no CORS).
 * - In the browser an optional proxy prefix can be configured in Settings.
 */

let corsProxyPrefix = '';

export function setCorsProxy(prefix: string): void {
  corsProxyPrefix = prefix.trim();
}

export class HttpError extends Error {
  constructor(message: string, public readonly status?: number) {
    super(message);
    this.name = 'HttpError';
  }
}

export function applyProxy(url: string, prefix: string = corsProxyPrefix): string {
  if (!prefix) return url;
  if (prefix.includes('{url}')) return prefix.replace('{url}', encodeURIComponent(url));
  return prefix + encodeURIComponent(url);
}

export interface HttpOptions {
  headers?: Record<string, string>;
  timeoutMs?: number;
}

export async function httpGetText(url: string, opts: HttpOptions = {}): Promise<string> {
  const timeoutMs = opts.timeoutMs ?? 60_000;

  if (isNativeApp()) {
    const res = await CapacitorHttp.get({
      url,
      headers: opts.headers,
      responseType: 'text',
      connectTimeout: timeoutMs,
      readTimeout: timeoutMs,
    });
    if (res.status < 200 || res.status >= 300) {
      throw new HttpError(`HTTP ${res.status}`, res.status);
    }
    return typeof res.data === 'string' ? res.data : JSON.stringify(res.data);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(applyProxy(url), { headers: opts.headers, signal: controller.signal });
    if (!res.ok) throw new HttpError(`HTTP ${res.status}`, res.status);
    return await res.text();
  } catch (err) {
    if (err instanceof HttpError) throw err;
    if ((err as Error).name === 'AbortError') throw new HttpError('Tempo limite excedido');
    throw new HttpError(
      corsProxyPrefix
        ? 'Falha de rede. Verifique a URL e o proxy configurado.'
        : 'Falha de rede ou bloqueio de CORS. No navegador, configure um proxy em Configurações ou use o app Android.'
    );
  } finally {
    clearTimeout(timer);
  }
}

export async function httpGetJson<T>(url: string, opts: HttpOptions = {}): Promise<T> {
  const text = await httpGetText(url, opts);
  try {
    return JSON.parse(text) as T;
  } catch {
    throw new HttpError('Resposta inválida do servidor (JSON esperado).');
  }
}

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export async function httpGetBytes(url: string, opts: HttpOptions = {}): Promise<Uint8Array> {
  const timeoutMs = opts.timeoutMs ?? 120_000;
  if (isNativeApp()) {
    const res = await CapacitorHttp.get({
      url,
      headers: opts.headers,
      responseType: 'arraybuffer',
      connectTimeout: timeoutMs,
      readTimeout: timeoutMs,
    });
    if (res.status < 200 || res.status >= 300) throw new HttpError(`HTTP ${res.status}`, res.status);
    // Capacitor returns binary bodies as base64 strings.
    return typeof res.data === 'string' ? base64ToBytes(res.data) : new Uint8Array(res.data as ArrayBuffer);
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(applyProxy(url), { headers: opts.headers, signal: controller.signal });
    if (!res.ok) throw new HttpError(`HTTP ${res.status}`, res.status);
    return new Uint8Array(await res.arrayBuffer());
  } catch (err) {
    if (err instanceof HttpError) throw err;
    throw new HttpError('Falha de rede ou bloqueio de CORS ao baixar o guia.');
  } finally {
    clearTimeout(timer);
  }
}

export function isGzip(bytes: Uint8Array): boolean {
  return bytes.length > 2 && bytes[0] === 0x1f && bytes[1] === 0x8b;
}

/** Downloads text that may be gzip-compressed (XMLTV guides are often .xml.gz). */
export async function httpGetMaybeGzipText(url: string, opts: HttpOptions = {}): Promise<string> {
  const bytes = await httpGetBytes(url, opts);
  if (!isGzip(bytes)) return new TextDecoder().decode(bytes);
  if (typeof DecompressionStream === 'undefined') {
    throw new HttpError('Este dispositivo não consegue descompactar guias .gz. Use a URL do guia sem compressão.');
  }
  const stream = new Blob([bytes as BlobPart]).stream().pipeThrough(new DecompressionStream('gzip'));
  return await new Response(stream).text();
}
