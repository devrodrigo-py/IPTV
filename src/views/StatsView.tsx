import React from 'react';
import {
  BarChart3,
  Clock,
  Sparkles,
  Tv,
  Calendar,
  TrendingUp,
  Award,
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const StatsView: React.FC = () => {
  const { stats, setIsWrappedOpen, filteredChannels } = useApp();

  const totalHours = (stats.totalMinutesWatched / 60).toFixed(1);
  const sortedChannels = Object.entries(stats.channelPlayCounts).sort((a, b) => b[1] - a[1]);
  const sortedGenres = Object.entries(stats.genreCounts).sort((a, b) => b[1] - a[1]);

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Estatísticas de Consumo</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Métricas de tempo de tela, canais mais acessados e gêneros favoritos.
          </p>
        </div>

        <button
          onClick={() => setIsWrappedOpen(true)}
          className="px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#6B4FE0] to-[#FF6F91] hover:opacity-90 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-[#6B4FE0]/30 transition-all cursor-pointer"
        >
          <Sparkles className="w-4 h-4 text-white" />
          Ver Nebula Wrapped
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-5 rounded-2xl bg-[#16162A] border border-[#2A2A45] flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-[#6B4FE0]/20 text-[#6B4FE0] flex items-center justify-center">
            <Clock className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-[#A8A6C0] uppercase tracking-wider block">
              Tempo Assistido
            </span>
            <span className="text-2xl font-black text-white font-mono">{totalHours} horas</span>
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-[#16162A] border border-[#2A2A45] flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-[#1FCFAE]/20 text-[#1FCFAE] flex items-center justify-center">
            <Calendar className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-[#A8A6C0] uppercase tracking-wider block">
              Dias Ativos
            </span>
            <span className="text-2xl font-black text-white font-mono">{stats.daysActive} dias</span>
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-[#16162A] border border-[#2A2A45] flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-[#FF6F91]/20 text-[#FF6F91] flex items-center justify-center">
            <Award className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-[#A8A6C0] uppercase tracking-wider block">
              Gênero Favorito
            </span>
            <span className="text-xl font-bold text-white truncate max-w-[160px] block">
              {sortedGenres[0]?.[0] || 'Geral'}
            </span>
          </div>
        </div>
      </div>

      {/* Content Split: Top Channels vs Genre breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Leaderboard */}
        <div className="p-5 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-[#1FCFAE]" />
            <h3 className="text-sm font-bold text-white">Canais Mais Sintonizados</h3>
          </div>

          <div className="space-y-3">
            {sortedChannels.slice(0, 6).map(([name, count], index) => {
              const maxCount = sortedChannels[0]?.[1] || 1;
              const pct = Math.round((count / maxCount) * 100);

              return (
                <div key={name} className="space-y-1">
                  <div className="flex justify-between text-xs">
                    <span className="font-semibold text-white flex items-center gap-2">
                      <span className="text-[#A8A6C0] font-mono w-4">{index + 1}.</span>
                      {name}
                    </span>
                    <span className="font-mono text-[#A8A6C0] font-bold">{count} sessões</span>
                  </div>
                  <div className="h-2 w-full bg-[#07070F] rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-[#6B4FE0] to-[#1FCFAE] rounded-full transition-all duration-500"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Categories Distribution */}
        <div className="p-5 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
          <div className="flex items-center gap-2">
            <Tv className="w-4 h-4 text-[#FF6F91]" />
            <h3 className="text-sm font-bold text-white">Distribuição por Categoria</h3>
          </div>

          <div className="space-y-3">
            {sortedGenres.map(([genre, count]) => {
              const totalPlays = Object.values(stats.genreCounts).reduce((a, b) => a + b, 0) || 1;
              const share = Math.round((count / totalPlays) * 100);

              return (
                <div key={genre} className="space-y-1">
                  <div className="flex justify-between text-xs">
                    <span className="font-semibold text-white">{genre}</span>
                    <span className="font-mono text-[#1FCFAE] font-bold">{share}%</span>
                  </div>
                  <div className="h-2 w-full bg-[#07070F] rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-[#2A1D6B] to-[#FF6F91] rounded-full transition-all duration-500"
                      style={{ width: `${share}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
