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
