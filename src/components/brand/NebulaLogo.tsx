import React from 'react';
import { markSvg } from './markSvg';

let seq = 0;

export const NebulaMark: React.FC<{ size?: number; className?: string; title?: string }> = ({ size = 40, className = '', title }) => {
  // Unique gradient ids: several marks can be on screen at once.
  const html = React.useMemo(() => markSvg(`nb${++seq}`, size), [size]);
  return (
    <span
      className={`inline-block shrink-0 ${className}`}
      style={{ width: size, height: size, lineHeight: 0 }}
      role={title ? 'img' : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
};

interface NebulaLogoProps {
  /** Height of the mark in px; the wordmark scales with it. */
  size?: number;
  showWordmark?: boolean;
  className?: string;
}

/** Mark + wordmark. The wordmark is lowercase Outfit Bold with slightly tight tracking. */
export const NebulaLogo: React.FC<NebulaLogoProps> = ({ size = 36, showWordmark = true, className = '' }) => (
  <span className={`inline-flex items-center select-none ${className}`}>
    <NebulaMark size={size} title={showWordmark ? undefined : 'Nebula'} />
    {showWordmark && (
      <span
        className="font-display font-bold text-white leading-none"
        style={{ fontSize: size * 0.78, letterSpacing: '-0.02em', marginLeft: size * 0.26, marginTop: -size * 0.06 }}
      >
        nebula
      </span>
    )}
  </span>
);
