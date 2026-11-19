import { Capacitor } from '@capacitor/core';

/** True inside the Android (Capacitor) build, false in a browser. */
export function isNativeApp(): boolean {
  try {
    return Capacitor.isNativePlatform();
  } catch {
    return false;
  }
}

export interface DeviceProfile {
  /** Amazon Fire TV / Fire Stick (user agent model starts with AFT). */
  isFireTv: boolean;
  /** Android TV / Google TV / Xiaomi Mi Box and Mi TV. */
  isAndroidTv: boolean;
  /** Little RAM or few cores: use lighter visuals and fewer decoders. */
  isLowEnd: boolean;
  /** How many streams the multiview may decode at once on this device. */
  maxMultiviewTiles: number;
}

export function detectDeviceProfile(
  ua: string = typeof navigator !== 'undefined' ? navigator.userAgent : '',
  memoryGb: number | undefined = typeof navigator !== 'undefined'
    ? (navigator as Navigator & { deviceMemory?: number }).deviceMemory
    : undefined,
  cores: number | undefined = typeof navigator !== 'undefined' ? navigator.hardwareConcurrency : undefined
): DeviceProfile {
  const isFireTv = /\bAFT[A-Z0-9]*\b/.test(ua) || /Fire ?TV/i.test(ua);
  const isAndroidTv =
    isFireTv || /Android TV|GoogleTV|BRAVIA|MiTV|MIBOX|Mi Box|SHIELD|Chromecast|\bTV\b/i.test(ua);
  const isLowEnd = (memoryGb !== undefined && memoryGb <= 2) || (cores !== undefined && cores <= 4 && isAndroidTv);
  return {
    isFireTv,
    isAndroidTv,
    isLowEnd,
    maxMultiviewTiles: isLowEnd ? 2 : isAndroidTv ? 4 : 9,
  };
}

let cached: DeviceProfile | null = null;
export function getDeviceProfile(): DeviceProfile {
  if (!cached) cached = detectDeviceProfile();
  return cached;
}
