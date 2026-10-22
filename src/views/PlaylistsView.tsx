import React, { useState } from 'react';
import {
  FolderGit2,
  Plus,
  RefreshCw,
  Trash2,
  CheckCircle2,
  XCircle,
  ExternalLink,
  Tv,
  Layers,
  Clock,
  Radio,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { PlaylistModal } from '../components/playlists/PlaylistModal';

export const PlaylistsView: React.FC = () => {
  const { playlists, deletePlaylist, togglePlaylist, refreshPlaylist, channels } = useApp();

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [refreshingId, setRefreshingId] = useState<string | null>(null);

  const handleRefresh = async (id: string) => {
    setRefreshingId(id);
    await refreshPlaylist(id);
    setTimeout(() => setRefreshingId(null), 800);
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <FolderGit2 className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Gerenciamento de Playlists</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Adicione, sincronize e controle suas fontes de transmissão M3U e servidores Xtream Codes.
          </p>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          className="px-5 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-[#6B4FE0]/30 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          Nova Playlist
        </button>
      </div>

      {/* Playlist Cards List */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {playlists.map((pl) => {
          const isRefreshing = refreshingId === pl.id;
          const liveChannelsCount = channels.filter((c) => c.playlistId === pl.id).length;

          return (
            <div
              key={pl.id}
              className={`p-5 rounded-2xl border transition-all ${
                pl.isActive
                  ? 'bg-[#16162A] border-[#2A2A45] hover:border-[#6B4FE0]/50'
                  : 'bg-[#0B0B18] border-[#2A2A45]/40 opacity-70'
              }`}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div
                    className={`w-11 h-11 rounded-xl flex items-center justify-center font-bold text-sm ${
                      pl.type === 'xtream'
                        ? 'bg-[#1FCFAE]/20 text-[#1FCFAE] border border-[#1FCFAE]/30'
                        : 'bg-[#6B4FE0]/20 text-[#6B4FE0] border border-[#6B4FE0]/30'
                    }`}
                  >
                    {pl.type === 'xtream' ? 'XC' : 'M3U'}
                  </div>
                  <div>
                    <h3 className="font-bold text-sm text-white flex items-center gap-2">
                      {pl.name}
                      {pl.isActive ? (
                        <span className="w-2 h-2 rounded-full bg-[#1FCFAE] animate-pulse" />
                      ) : (
                        <span className="w-2 h-2 rounded-full bg-[#A8A6C0]" />
                      )}
                    </h3>
                    <span className="text-[11px] text-[#A8A6C0] font-mono">
                      {pl.type === 'xtream' ? 'Xtream Codes Server' : 'Lista M3U / M3U8'}
                    </span>
                  </div>
                </div>

                {/* Active switch */}
                <button
                  onClick={() => togglePlaylist(pl.id)}
                  className={`px-3 py-1 rounded-full text-[11px] font-bold cursor-pointer transition-all ${
                    pl.isActive
                      ? 'bg-[#1FCFAE]/20 text-[#1FCFAE] border border-[#1FCFAE]/40'
                      : 'bg-[#2A2A45] text-[#A8A6C0]'
                  }`}
                >
                  {pl.isActive ? 'Ativa' : 'Desativada'}
                </button>
              </div>

              {/* Source preview */}
              {pl.url && (
                <p className="text-xs text-[#A8A6C0] font-mono truncate mb-4 bg-[#07070F] p-2 rounded-lg border border-white/5">
                  {pl.url}
                </p>
              )}

              {/* Stats Bar */}
              <div className="grid grid-cols-2 gap-2 py-3 border-t border-[#2A2A45]/60 text-xs">
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#A8A6C0] block">
                    Canais Extraídos
                  </span>
                  <span className="font-mono font-bold text-white flex items-center gap-1.5 mt-0.5">
                    <Tv className="w-3.5 h-3.5 text-[#1FCFAE]" />
                    {liveChannelsCount || pl.channelCount} canais
                  </span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#A8A6C0] block">
                    Última Sincronização
                  </span>
                  <span className="font-mono text-[11px] text-[#A8A6C0] flex items-center gap-1 mt-0.5">
                    <Clock className="w-3.5 h-3.5" />
                    {new Date(pl.lastSync).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              </div>

              {/* Actions Footer */}
              <div className="flex items-center justify-between pt-3 border-t border-[#2A2A45]/60 mt-1">
                <button
                  onClick={() => handleRefresh(pl.id)}
                  disabled={isRefreshing}
                  className="flex items-center gap-1.5 text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-semibold cursor-pointer transition-colors"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-[#1FCFAE]' : ''}`} />
                  {isRefreshing ? 'Sincronizando...' : 'Recarregar Canais'}
                </button>

                <button
                  onClick={() => deletePlaylist(pl.id)}
                  className="flex items-center gap-1.5 text-xs text-[#FF5468] hover:text-[#FF5468]/80 font-semibold cursor-pointer transition-colors"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  Excluir
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {isAddModalOpen && <PlaylistModal onClose={() => setIsAddModalOpen(false)} />}
    </div>
  );
};
