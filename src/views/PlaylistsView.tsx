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
import { ConfirmModal } from '../components/common/ConfirmModal';
import { Playlist } from '../types';

/** Hides credentials that providers put in M3U links (…?username=x&password=y). */
function maskUrl(url: string): string {
  return url.replace(/(password=)[^&]+/i, '$1••••').replace(/(\/(?:live|movie|series|get)\/[^/]+\/)[^/]+/i, '$1••••');
}

export const PlaylistsView: React.FC = () => {
  const { playlists, deletePlaylist, togglePlaylist, refreshPlaylist, syncStatus, loadDemoContent } = useApp();
  const [refreshMessage, setRefreshMessage] = useState<{ id: string; ok: boolean; text: string } | null>(null);

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [refreshingId, setRefreshingId] = useState<string | null>(null);
  const [playlistToDelete, setPlaylistToDelete] = useState<Playlist | null>(null);

  const handleRefresh = async (id: string) => {
    setRefreshingId(id);
    setRefreshMessage(null);
    const res = await refreshPlaylist(id);
    setRefreshingId(null);
    setRefreshMessage({
      id,
      ok: res.success,
      text: res.success
        ? `Atualizada: ${res.channelCount} canais, ${res.vodCount ?? 0} filmes, ${res.seriesCount ?? 0} séries.`
        : res.message || 'Falha ao atualizar.',
    });
  };

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <FolderGit2 className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Minhas listas</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Adicione, sincronize e controle suas fontes de transmissão M3U e servidores Xtream Codes.
          </p>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          data-tv-title="Nova lista"
          className="tv-card focus:outline-none px-5 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-[#6B4FE0]/30 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          Nova Playlist
        </button>
      </div>

      {playlists.length === 0 && (
        <div className="p-10 text-center bg-[#16162A]/50 rounded-3xl border border-[#2A2A45] space-y-4">
          <p className="text-sm text-[#A8A6C0]">
            Nenhuma lista ainda. Adicione o link M3U ou o login Xtream Codes fornecido pelo seu provedor.
          </p>
          <div className="flex justify-center gap-3">
            <button
              onClick={() => setIsAddModalOpen(true)}
              autoFocus
              data-tv-title="Adicionar lista"
              className="tv-card px-5 py-2.5 rounded-xl bg-[#6B4FE0] text-white font-bold text-xs cursor-pointer focus:outline-none"
            >
              Adicionar lista
            </button>
            <button
              onClick={loadDemoContent}
              data-tv-title="Carregar demonstração"
              className="tv-card px-5 py-2.5 rounded-xl bg-white/10 text-white font-semibold text-xs cursor-pointer focus:outline-none"
            >
              Carregar demonstração
            </button>
          </div>
        </div>
      )}

      {/* Playlist Cards List */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {playlists.map((pl) => {
          const isRefreshing = refreshingId === pl.id || syncStatus?.playlistId === pl.id;
          const expires = pl.expiresAt ? new Date(pl.expiresAt) : null;
          const expiresSoon = expires ? expires.getTime() - Date.now() < 7 * 86400_000 : false;

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
                  data-tv-title={pl.isActive ? `Desativar ${pl.name}` : `Ativar ${pl.name}`}
                  className={`tv-card focus:outline-none px-3 py-1 rounded-full text-[11px] font-bold cursor-pointer transition-all ${
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
                  {maskUrl(pl.url)}
                  {pl.username ? ` · ${pl.username}` : ''}
                </p>
              )}

              {/* Stats Bar */}
              <div className="grid grid-cols-2 gap-2 py-3 border-t border-[#2A2A45]/60 text-xs">
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#A8A6C0] block">Conteúdo</span>
                  <span className="font-mono font-bold text-white flex items-center gap-1.5 mt-0.5">
                    <Tv className="w-3.5 h-3.5 text-[#1FCFAE]" />
                    {pl.channelCount} canais · {pl.vodCount ?? 0} filmes · {pl.seriesCount ?? 0} séries
                  </span>
                </div>
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#A8A6C0] block">
                    Última Sincronização
                  </span>
                  <span className="font-mono text-[11px] text-[#A8A6C0] flex items-center gap-1 mt-0.5">
                    <Clock className="w-3.5 h-3.5" />
                    {new Date(pl.lastSync).toLocaleString([], { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
              </div>

              {(expires || pl.epgUrl) && (
                <div className="flex flex-wrap gap-3 text-[11px] pb-2">
                  {expires && (
                    <span className={expiresSoon ? 'text-[#FF5468] font-bold' : 'text-[#A8A6C0]'}>
                      Assinatura até {expires.toLocaleDateString()}
                    </span>
                  )}
                  {pl.epgUrl && (
                    <span className="text-[#A8A6C0]">
                      Guia: {pl.epgLastSync ? `atualizado ${new Date(pl.epgLastSync).toLocaleDateString()}` : 'pendente'}
                    </span>
                  )}
                </div>
              )}

              {isRefreshing && syncStatus?.playlistId === pl.id && (
                <p className="text-[11px] text-[#1FCFAE] pb-2">{syncStatus.step}</p>
              )}
              {!isRefreshing && refreshMessage?.id === pl.id && (
                <p className={`text-[11px] pb-2 ${refreshMessage.ok ? 'text-[#1FCFAE]' : 'text-[#FF5468]'}`}>{refreshMessage.text}</p>
              )}
              {!isRefreshing && refreshMessage?.id !== pl.id && pl.lastError && (
                <p className="text-[11px] pb-2 text-[#FF5468]">Última atualização falhou: {pl.lastError}</p>
              )}

              {/* Actions Footer */}
              <div className="flex items-center justify-between pt-3 border-t border-[#2A2A45]/60 mt-1">
                <button
                  onClick={() => handleRefresh(pl.id)}
                  disabled={isRefreshing}
                  data-tv-title={`Atualizar ${pl.name}`}
                  className="tv-card px-2 py-1 rounded-lg focus:outline-none flex items-center gap-1.5 text-xs text-[#A8A6C0] hover:text-[#1FCFAE] font-semibold cursor-pointer transition-colors"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-[#1FCFAE]' : ''}`} />
                  {isRefreshing ? 'Sincronizando...' : 'Atualizar'}
                </button>

                <button
                  onClick={() => setPlaylistToDelete(pl)}
                  data-tv-title={`Excluir ${pl.name}`}
                  className="tv-card px-2 py-1 rounded-lg focus:outline-none flex items-center gap-1.5 text-xs text-[#FF5468] hover:text-[#FF5468]/80 font-semibold cursor-pointer transition-colors"
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

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={playlistToDelete !== null}
        title="Remover Playlist?"
        message={`Deseja realmente remover a playlist "${playlistToDelete?.name}"? Todos os canais associados a esta fonte serão removidos da sua grade.`}
        confirmLabel="Excluir Playlist"
        cancelLabel="Cancelar"
        isDestructive={true}
        onConfirm={() => {
          if (playlistToDelete) {
            deletePlaylist(playlistToDelete.id);
            setPlaylistToDelete(null);
          }
        }}
        onCancel={() => setPlaylistToDelete(null)}
      />
    </div>
  );
};
