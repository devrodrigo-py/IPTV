/**
 * Single source of the Nebula mark. Used by the React component and by
 * scripts/generate-brand.ts (launcher icons, TV banner, splash, favicon).
 *
 * The mark is a small world with a play button at its core and a tilted
 * orbit in the nebula gradient (violet → magenta → amber). The back of the
 * orbit passes behind the sphere and the front passes over it, which gives
 * depth at any size, from a 48 px launcher icon to the TV banner.
 */
export function markSvg(id: string, size: number | string = 64): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 64 64">
<defs>
<radialGradient id="${id}c" cx="0.36" cy="0.3" r="0.8"><stop offset="0" stop-color="#A88CFF"/><stop offset="0.55" stop-color="#5B3FE0"/><stop offset="1" stop-color="#22145F"/></radialGradient>
<linearGradient id="${id}o" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8B6CFF"/><stop offset="0.5" stop-color="#FF4D8D"/><stop offset="1" stop-color="#FFB36B"/></linearGradient>
<clipPath id="${id}f"><rect x="0" y="32" width="64" height="32"/></clipPath>
</defs>
<g transform="rotate(-22 32 32)"><ellipse cx="32" cy="32" rx="29" ry="9" fill="none" stroke="url(#${id}o)" stroke-width="3.6" opacity="0.55"/></g>
<circle cx="32" cy="32" r="17.5" fill="url(#${id}c)"/>
<path d="M28 24.2 L40.6 32 L28 39.8 Z" fill="#fff" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>
<g transform="rotate(-22 32 32)" clip-path="url(#${id}f)"><ellipse cx="32" cy="32" rx="29" ry="9" fill="none" stroke="url(#${id}o)" stroke-width="3.6"/></g>
<path d="M53 4 L54.3 8.2 L58.5 9.5 L54.3 10.8 L53 15 L51.7 10.8 L47.5 9.5 L51.7 8.2 Z" fill="#fff" opacity="0.9"/>
</svg>`;
}
