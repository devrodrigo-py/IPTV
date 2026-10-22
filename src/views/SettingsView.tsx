import React, { useState } from 'react';
import {
  Settings,
  Shield,
  Layers,
  Download,
  Upload,
  RefreshCw,
  Tv,
  CheckCircle,
  AlertCircle,
  Database,
  Lock,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { exportNebulaData, importNebulaData } from '../data/storage';

export const SettingsView: React.FC = () => {
  const { settings, updateSettings, tvMode, toggleTvMode } = useApp();

  const [pinInput, setPinInput] = useState(settings.masterPin);
  const [pinSavedFeedback, setPinSavedFeedback] = useState(false);
  const [backupFeedback, setBackupFeedback] = useState<string | null>(null);

  const handleSavePin = () => {
    if (pinInput.trim().length >= 4) {
      updateSettings({ masterPin: pinInput.trim() });
      setPinSavedFeedback(true);
      setTimeout(() => setPinSavedFeedback(false), 2000);
    }
  };

  const handleExportBackup = () => {
    const jsonStr = exportNebulaData();
    const blob = new Blob([jsonStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `nebula_iptv_backup_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    setBackupFeedback('Backup exportado com sucesso!');
    setTimeout(() => setBackupFeedback(null), 3000);
  };

  const handleImportBackup = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const text = event.target?.result as string;
        if (text) {
          const ok = importNebulaData(text);
          if (ok) {
            setBackupFeedback('Backup restaurado com sucesso! Recarregando...');
            setTimeout(() => window.location.reload(), 1200);
          } else {
            setBackupFeedback('Falha ao restaurar: Arquivo JSON inválido.');
          }
        }
      };
      reader.readAsText(file);
    }
  };

  const handleClearCache = () => {
    if (confirm('Deseja realmente limpar o cache de imagens e buffers locais?')) {
      localStorage.removeItem('nebula_epg');
      setBackupFeedback('Cache limpo com sucesso.');
      setTimeout(() => setBackupFeedback(null), 2500);
    }
  };

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-8 select-none">
      {/* Header */}
      <div className="pb-4 border-b border-[#2A2A45]">
        <div className="flex items-center gap-2">
          <Settings className="w-5 h-5 text-[#6B4FE0]" />
          <h1 className="text-xl font-bold text-white tracking-tight">Configurações do Sistema</h1>
        </div>
        <p className="text-xs text-[#A8A6C0] mt-0.5">
          Personalize a reprodução de vídeo, segurança, interface e backups.
        </p>
      </div>

      {backupFeedback && (
        <div className="p-3.5 rounded-2xl bg-[#1FCFAE]/20 border border-[#1FCFAE]/40 text-xs text-[#1FCFAE] font-bold flex items-center gap-2">
          <CheckCircle className="w-4 h-4" />
          {backupFeedback}
        </div>
      )}

      {/* 1. Stream Playback & Buffer settings */}
      <section className="p-6 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
        <div className="flex items-center gap-2 text-white font-bold text-sm">
          <Tv className="w-4 h-4 text-[#6B4FE0]" />
          Reprodução & Buffer de Transmissão
        </div>

        <div className="space-y-3">
          <div>
            <label className="block text-xs font-semibold text-[#A8A6C0] mb-2">
              Modo do Buffer de Stream
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {[
                { id: 'low', title: 'Baixa Latência', desc: 'Início instantâneo (2s buffer)' },
                { id: 'balanced', title: 'Equilibrado (Recomendado)', desc: 'Estável e rápido (15s buffer)' },
                { id: 'high', title: 'Buffer Alto', desc: 'Anti-travamento em redes lentas' },
              ].map((opt) => (
                <button
                  key={opt.id}
                  onClick={() => updateSettings({ bufferMode: opt.id as any })}
                  className={`p-3.5 rounded-2xl border text-left cursor-pointer transition-all ${
                    settings.bufferMode === opt.id
                      ? 'bg-[#6B4FE0]/20 border-[#6B4FE0] text-white'
                      : 'bg-[#07070F] border-[#2A2A45] text-[#A8A6C0] hover:text-white'
                  }`}
                >
                  <p className="text-xs font-bold">{opt.title}</p>
                  <p className="text-[11px] opacity-70 mt-0.5">{opt.desc}</p>
                </button>
              ))}
            </div>
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-[#2A2A45]/60">
            <div>
              <p className="text-xs font-bold text-white">Reprodução Automática (Autoplay)</p>
              <p className="text-[11px] text-[#A8A6C0]">
                Iniciar o streaming do canal imediatamente ao clicar
              </p>
            </div>
            <input
              type="checkbox"
              checked={settings.streamAutoplay}
              onChange={(e) => updateSettings({ streamAutoplay: e.target.checked })}
              className="w-5 h-5 accent-[#6B4FE0] rounded cursor-pointer"
            />
          </div>
        </div>
      </section>

      {/* 2. TV Navigation Mode */}
      <section className="p-6 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-white font-bold text-sm">
            <Tv className="w-4 h-4 text-[#1FCFAE]" />
            Modo Android TV / 10-Foot UI (Controle Remoto)
          </div>
          <button
            onClick={toggleTvMode}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer ${
              tvMode
                ? 'bg-[#1FCFAE] text-black shadow-lg shadow-[#1FCFAE]/30'
                : 'bg-[#2A2A45] text-[#A8A6C0]'
            }`}
          >
            {tvMode ? 'Ativado' : 'Desativado'}
          </button>
        </div>
        <p className="text-xs text-[#A8A6C0]">
          Habilita os anéis de foco iluminados Nebula, controle remoto flutuante na tela e navegação D-pad pelas teclas direcionais do teclado.
        </p>
      </section>

      {/* 3. Parental Control */}
      <section className="p-6 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-white font-bold text-sm">
            <Shield className="w-4 h-4 text-[#FF6F91]" />
            Controle Parental & Proteção por PIN
          </div>
          <input
            type="checkbox"
            checked={settings.parentalControlEnabled}
            onChange={(e) => updateSettings({ parentalControlEnabled: e.target.checked })}
            className="w-5 h-5 accent-[#FF6F91] rounded cursor-pointer"
          />
        </div>
        <p className="text-xs text-[#A8A6C0]">
          Bloqueia canais adultos e restringe perfis infantis (Kids) de acessar configurações ou trocar de perfil sem a senha.
        </p>

        {settings.parentalControlEnabled && (
          <div className="pt-2 flex items-center gap-3">
            <div className="relative w-48">
              <Lock className="w-4 h-4 text-[#A8A6C0] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                maxLength={6}
                value={pinInput}
                onChange={(e) => setPinInput(e.target.value)}
                placeholder="PIN Mestre (4-6 dígitos)"
                className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl pl-9 pr-3 py-2 text-xs text-white tracking-widest outline-none focus:border-[#FF6F91]"
              />
            </div>
            <button
              onClick={handleSavePin}
              className="px-4 py-2 rounded-xl bg-[#FF6F91] hover:bg-[#FF6F91]/80 text-white font-bold text-xs cursor-pointer transition-colors"
            >
              {pinSavedFeedback ? 'Salvo!' : 'Atualizar PIN'}
            </button>
          </div>
        )}
      </section>

      {/* 4. Backup & Cache Management */}
      <section className="p-6 rounded-3xl bg-[#16162A] border border-[#2A2A45] space-y-4">
        <div className="flex items-center gap-2 text-white font-bold text-sm">
          <Database className="w-4 h-4 text-[#6B4FE0]" />
          Importação, Exportação e Cache
        </div>
        <p className="text-xs text-[#A8A6C0]">
          Faça backup de todos os seus canais, playlists, favoritos e perfis em formato JSON.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
          <button
            onClick={handleExportBackup}
            className="p-3.5 rounded-2xl bg-[#07070F] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] text-white flex flex-col items-center justify-center gap-2 cursor-pointer transition-all"
          >
            <Download className="w-5 h-5 text-[#1FCFAE]" />
            <span className="text-xs font-bold">Exportar Backup</span>
          </button>

          <label className="p-3.5 rounded-2xl bg-[#07070F] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] text-white flex flex-col items-center justify-center gap-2 cursor-pointer transition-all text-center">
            <Upload className="w-5 h-5 text-[#6B4FE0]" />
            <span className="text-xs font-bold">Restaurar Backup</span>
            <input
              type="file"
              accept=".json"
              onChange={handleImportBackup}
              className="hidden"
            />
          </label>

          <button
            onClick={handleClearCache}
            className="p-3.5 rounded-2xl bg-[#07070F] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#FF5468] text-white flex flex-col items-center justify-center gap-2 cursor-pointer transition-all"
          >
            <RefreshCw className="w-5 h-5 text-[#FF5468]" />
            <span className="text-xs font-bold">Limpar Cache</span>
          </button>
        </div>
      </section>
    </div>
  );
};
