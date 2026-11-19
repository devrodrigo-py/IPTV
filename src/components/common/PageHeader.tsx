import React from 'react';

interface PageHeaderProps {
  title: string;
  subtitle?: React.ReactNode;
  actions?: React.ReactNode;
}

/** Shared page title: large display type, quiet subtitle, optional actions on the right. */
export const PageHeader: React.FC<PageHeaderProps> = ({ title, subtitle, actions }) => (
  <header className="flex flex-wrap items-end justify-between gap-4 pb-6">
    <div>
      <h1 className="font-display text-4xl font-bold text-white tracking-tight">{title}</h1>
      {subtitle && <p className="text-white/50 mt-1.5 text-base">{subtitle}</p>}
    </div>
    {actions && <div className="flex items-center gap-3">{actions}</div>}
  </header>
);
