import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.nebula.iptv',
  appName: 'Nebula IPTV',
  webDir: 'dist',
  android: {
    // IPTV logos and EPG images are often served over plain HTTP.
    allowMixedContent: true,
    // Remote controls send key events; keep the WebView focusable and not zoomable.
    captureInput: false,
    webContentsDebuggingEnabled: false,
  },
  server: {
    androidScheme: 'https',
  },
  plugins: {
    // Requests go through CapacitorHttp explicitly (platform/http.ts); do not
    // patch window.fetch/XHR, which hls.js relies on for media segments.
    CapacitorHttp: { enabled: false },
  },
};

export default config;
