import React, { useState } from 'react';
import { X, FolderGit2, Link2, Upload, Server, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { PlaylistType } from '../../types';

interface PlaylistModalProps {
  onClose: () => void;
}

export const PlaylistModal: React.FC<PlaylistModalProps> = ({ onClose }) => {
  const { addPlaylist } = useApp();

  const [playlistType, setPlaylistType] = useState<PlaylistType>('m3u');
  const [importMode, setImportMode] = useState<'url' | 'file'>('url');
  const [name, setName] = useState('');
  const [url, setUrl] = useState('');
  const [fileContent, setFileContent] = useState('');
  const [fileName, setFileName] = useState('');

  // Xtream credentials
  const [serverUrl, setServerUrl] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const [isLoading, setIsLoading] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'error' | 'success'; message: string } | null>(null);

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setFileName(file.name);
      if (!name) setName(file.name.replace(/\.[^/.]+$/, ''));
      const reader = new FileReader();
      reader.onload = (event) => {
        const text = event.target?.result as string;
        setFileContent(text);
      };
      reader.readAsText(file);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setFeedback({ type: 'error', message: 'Por favor, insira um nome para a playlist.' });
      return;
    }

    setIsLoading(true);
    setFeedback(null);

    let res;
    if (playlistType === 'm3u') {
      if (importMode === 'url' && !url.trim()) {
        setIsLoading(false);
        setFeedback({ type: 'error', message: 'Por favor, insira a URL da playlist M3U.' });
        return;
      }
      if (importMode === 'file' && !fileContent) {
        setIsLoading(false);
        setFeedback({ type: 'error', message: 'Por favor, selecione um arquivo M3U válido.' });
        return;
      }

      res = await addPlaylist(name, 'm3u', {
        url: importMode === 'url' ? url.trim() : undefined,
        content: importMode === 'file' ? fileContent : undefined,
      });
    } else {
      // Xtream
      if (!serverUrl.trim() || !username.trim() || !password.trim()) {
        setIsLoading(false);
        setFeedback({ type: 'error', message: 'Preencha o endereço do servidor, usuário e senha.' });
        return;
      }

      res = await addPlaylist(name, 'xtream', {
        url: serverUrl.trim(),
        username: username.trim(),
        password: password.trim(),
      });
    }

    setIsLoading(false);

    if (res.success) {
      setFeedback({
        type: 'success',
        message: `Playlist adicionada com sucesso! ${res.channelCount} canais carregados.`,
      });
      setTimeout(() => {
        onClose();
      }, 1200);
    } else {
      setFeedback({
        type: 'error',
        message: res.message || 'Erro ao processar playlist.',
      });
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
      <div className="w-full max-w-lg bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative animate-in zoom-in-95 duration-200">
        <button
          onClick={onClose}
          className="absolute top-5 right-5 w-8 h-8 rounded-full bg-[#1E1E38] hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer transition-colors"
        >
          <X className="w-4 h-4" />
        </button>

        <div className="flex items-center gap-2 mb-1">
          <FolderGit2 className="w-5 h-5 text-[#6B4FE0]" />
          <h2 className="text-lg font-bold text-white">Adicionar Nova Fonte IPTV</h2>
        </div>
        <p className="text-xs text-[#A8A6C0] mb-5">
          Suporte completo a listas M3U/M3U8 e servidores Xtream Codes API.
        </p>

        {/* Type tabs: M3U vs Xtream Codes */}
        <div className="grid grid-cols-2 gap-2 p-1 bg-[#07070F] rounded-2xl mb-5 border border-[#2A2A45]">
          <button
            type="button"
            onClick={() => setPlaylistType('m3u')}
            className={`py-2 text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer ${
              playlistType === 'm3u'
                ? 'bg-[#6B4FE0] text-white shadow'
                : 'text-[#A8A6C0] hover:text-white'
            }`}
          >
            <Link2 className="w-3.5 h-3.5" />
            Lista M3U / M3U8
          </button>
          <button
            type="button"
            onClick={() => setPlaylistType('xtream')}
            className={`py-2 text-xs font-bold rounded-xl transition-all flex items-center justify-center gap-2 cursor-pointer ${
              playlistType === 'xtream'
                ? 'bg-[#6B4FE0] text-white shadow'
                : 'text-[#A8A6C0] hover:text-white'
            }`}
          >
            <Server className="w-3.5 h-3.5" />
            Xtream Codes API
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
              Nome da Lista
            </label>
            <input
              type="text"
              required
              placeholder="Ex: Minha Lista Brasil, Grade de Esportes..."
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none"
            />
          </div>

          {playlistType === 'm3u' ? (
            <>
              {/* URL or File toggle */}
              <div className="flex items-center gap-4 text-xs font-medium text-[#A8A6C0] py-1">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="importMode"
                    checked={importMode === 'url'}
                    onChange={() => setImportMode('url')}
                    className="accent-[#6B4FE0]"
                  />
                  <span>URL Web (Link Direto)</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="importMode"
                    checked={importMode === 'file'}
                    onChange={() => setImportMode('file')}
                    className="accent-[#6B4FE0]"
                  />
                  <span>Upload de Arquivo Local (.m3u)</span>
                </label>
              </div>

              {importMode === 'url' ? (
                <div>
                  <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                    URL da Lista M3U
                  </label>
                  <input
                    type="url"
                    placeholder="https://exemplo.com/lista.m3u8"
                    value={url}
                    onChange={(e) => setUrl(e.target.value)}
                    className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none font-mono"
                  />
                </div>
              ) : (
                <div>
                  <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                    Arquivo M3U / M3U8
                  </label>
                  <input
                    type="file"
                    accept=".m3u,.m3u8,.txt"
                    onChange={handleFileUpload}
                    className="w-full text-xs text-[#A8A6C0] file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-[#6B4FE0] file:text-white hover:file:bg-[#6B4FE0]/80 cursor-pointer"
                  />
                  {fileName && (
                    <span className="text-[11px] text-[#1FCFAE] font-medium block mt-1">
                      Arquivo selecionado: {fileName}
                    </span>
                  )}
                </div>
              )}
            </>
          ) : (
            <>
              <div>
                <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                  Endereço do Servidor (com porta)
                </label>
                <input
                  type="text"
                  placeholder="http://servidor-iptv.net:8080"
                  value={serverUrl}
                  onChange={(e) => setServerUrl(e.target.value)}
                  className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                    Usuário
                  </label>
                  <input
                    type="text"
                    placeholder="Usuário"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                    Senha
                  </label>
                  <input
                    type="password"
                    placeholder="Senha"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none"
                  />
                </div>
              </div>
            </>
          )}

          {feedback && (
            <div
              className={`p-3 rounded-xl flex items-center gap-2 text-xs font-medium ${
                feedback.type === 'success'
                  ? 'bg-[#1FCFAE]/20 border border-[#1FCFAE]/30 text-[#1FCFAE]'
                  : 'bg-[#FF5468]/20 border border-[#FF5468]/30 text-[#FF5468]'
              }`}
            >
              {feedback.type === 'success' ? (
                <CheckCircle className="w-4 h-4 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 shrink-0" />
              )}
              <span>{feedback.message}</span>
            </div>
          )}

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-[#2A2A45]">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl bg-[#1E1E38] hover:bg-[#2A2A45] text-xs font-semibold text-[#A8A6C0] cursor-pointer"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="px-5 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 disabled:opacity-50 text-white text-xs font-bold flex items-center gap-2 cursor-pointer shadow-lg shadow-[#6B4FE0]/30"
            >
              {isLoading && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              {isLoading ? 'Importando e Processando...' : 'Salvar e Sincronizar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
