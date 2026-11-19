import React, { useState } from 'react';

/** Built-in avatars: no network needed (TV boxes are often offline or blocked). */
export const AVATAR_PRESETS = [
  'preset:0',
  'preset:1',
  'preset:2',
  'preset:3',
  'preset:4',
  'preset:5',
];

const GRADIENTS = [
  'linear-gradient(135deg, #7C5CFF 0%, #2B1F66 100%)',
  'linear-gradient(135deg, #22D3A6 0%, #0E6B5A 100%)',
  'linear-gradient(135deg, #FF6F91 0%, #8A2443 100%)',
  'linear-gradient(135deg, #FFB547 0%, #A3520C 100%)',
  'linear-gradient(135deg, #3FA9F5 0%, #12406B 100%)',
  'linear-gradient(135deg, #B06BFF 0%, #FF6F91 100%)',
];

function presetIndex(avatar: string | undefined, name: string): number {
  const m = avatar?.match(/^preset:(\d+)$/);
  if (m) return parseInt(m[1], 10) % GRADIENTS.length;
  let h = 0;
  for (const ch of name) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return h % GRADIENTS.length;
}

interface AvatarProps {
  avatar?: string;
  name: string;
  className?: string;
  textClassName?: string;
}

export const Avatar: React.FC<AvatarProps> = ({ avatar, name, className = '', textClassName = 'text-4xl' }) => {
  const [broken, setBroken] = useState(false);
  const isImage = !!avatar && !avatar.startsWith('preset:') && !broken;
  if (isImage) {
    return <img src={avatar} alt="" onError={() => setBroken(true)} className={`object-cover ${className}`} />;
  }
  return (
    <div
      className={`flex items-center justify-center font-black text-white select-none ${className}`}
      style={{ background: GRADIENTS[presetIndex(avatar, name)] }}
      aria-hidden
    >
      <span className={textClassName}>{(name.trim().charAt(0) || '?').toUpperCase()}</span>
    </div>
  );
};
