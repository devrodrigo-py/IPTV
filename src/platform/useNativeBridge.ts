import { useEffect } from 'react';
import { App as CapApp } from '@capacitor/app';
import { isNativeApp } from './platform';

/** Remote keys the Android WebView reports that the app maps to its own shortcuts. */
const KEY_ALIASES: Record<string, string> = {
  MediaPlayPause: ' ',
  MediaPlay: ' ',
  MediaPause: ' ',
  MediaFastForward: 'ArrowRight',
  MediaRewind: 'ArrowLeft',
  ChannelUp: 'PageUp',
  ChannelDown: 'PageDown',
  GoBack: 'Escape',
  BrowserBack: 'Escape',
};

export const EXIT_EVENT = 'nebula:exit-request';

function dispatchKey(key: string) {
  window.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
}

/**
 * Connects Android TV hardware to the web UI:
 * - the remote's Back button (otherwise it closes the app on every press);
 * - media and channel keys, translated to the keys the UI already handles;
 * - leaving the app when Back is pressed at the top level.
 */
export function useNativeBridge(): void {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const alias = KEY_ALIASES[e.key];
      if (!alias || !e.isTrusted) return;
      e.preventDefault();
      dispatchKey(alias);
    };
    window.addEventListener('keydown', onKey, true);

    let removeBack: (() => void) | undefined;
    const onExit = () => {
      if (isNativeApp()) void CapApp.exitApp();
    };
    window.addEventListener(EXIT_EVENT, onExit);

    if (isNativeApp()) {
      CapApp.addListener('backButton', () => {
        // Text fields: Back closes the on-screen keyboard and leaves the field.
        const el = document.activeElement as HTMLElement | null;
        if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
          el.blur();
          return;
        }
        dispatchKey('Escape');
      }).then((h) => {
        removeBack = () => void h.remove();
      });
    }

    return () => {
      window.removeEventListener('keydown', onKey, true);
      window.removeEventListener(EXIT_EVENT, onExit);
      removeBack?.();
    };
  }, []);
}
