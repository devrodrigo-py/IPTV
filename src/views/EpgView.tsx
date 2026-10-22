import React, { useState } from 'react';
import {
  Calendar,
  Clock,
  Play,
  Upload,
  Info,
  Tv,
  CheckCircle,
  AlertCircle,
  X,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { EpgProgram, Channel } from '../types';

export const EpgView: React.FC = () => {
  const { filteredChannels, epgPrograms, getChannelPrograms, playChannel, importXmltv } = useApp();

  const [selectedProgram, setSelectedProgram] = useState<{
    program: EpgProgram;
    channel: Channel;
  } | null>(null);

  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [xmltvInput, setXmltvInput] = useState('');
  const [importStatus, setImportStatus] = useState<string | null>(null);

  const handleXmltvImport = () => {
    if (!xmltvInput.trim()) return;
    const res = importXmltv(xmltvInput);
    if (res.success) {
      setImportStatus(`Sucesso! ${res.programCount} programas importados do XMLTV.`);
      setTimeout(() => {
        setIsImportModalOpen(false);
        setImportStatus(null);
        setXmltvInput('');
      }, 1500);
    } else {
      setImportStatus('Nenhum programa válido encontrado no XMLTV.');
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const text = event.target?.result as string;
        if (text) {
          const res = importXmltv(text);
          if (res.success) {
            setImportStatus(`Sucesso! ${res.programCount} programas importados do arquivo XMLTV.`);
            setTimeout(() => {
              setIsImportModalOpen(false);
              setImportStatus(null);
            }, 1500);
          } else {
            setImportStatus('Nenhum programa válido encontrado no arquivo.');
          }
        }
      };
      reader.readAsText(file);
    }
  };

  const formatHour = (isoString: string) => {
    try {
      const d = new Date(isoString);
      return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    } catch {
      return '--:--';
    }
  };

  const isNow = (startIso: string, endIso: string) => {
    const now = Date.now();
    const s = new Date(startIso).getTime();
    const e = new Date(endIso).getTime();
    return now >= s && now <= e;
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Guia Eletrônico de Programação (EPG)</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Horários sincronizados em UTC e adaptados ao horário local do seu dispositivo.
          </p>
        </div>

        <button
          onClick={() => setIsImportModalOpen(true)}
          className="px-4 py-2 rounded-xl bg-[#16162A] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] text-xs font-semibold text-white flex items-center gap-2 transition-all cursor-pointer shadow-sm"
        >
          <Upload className="w-4 h-4 text-[#1FCFAE]" />
          Importar XMLTV (.xml)
        </button>
      </div>

      {/* Channel Rows Timeline */}
      <div className="space-y-4">
        {filteredChannels.map((channel) => {
          const programs = getChannelPrograms(channel.id);

          return (
            <div
              key={channel.id}
              className="bg-[#16162A]/60 rounded-2xl border border-[#2A2A45]/60 p-4 transition-all hover:border-[#6B4FE0]/40"
            >
              <div className="flex flex-col md:flex-row md:items-center gap-4">
                {/* Channel Header */}
                <div
                  onClick={() => playChannel(channel)}
                  className="w-full md:w-56 shrink-0 flex items-center gap-3 cursor-pointer group"
                >
                  <div className="w-10 h-10 rounded-xl bg-black/40 p-1 flex items-center justify-center border border-white/5">
                    {channel.logoUrl ? (
                      <img
                        src={channel.logoUrl}
                        alt={channel.name}
                        className="max-h-7 max-w-full object-contain"
                        onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
                      />
                    ) : (
                      <Tv className="w-5 h-5 text-[#6B4FE0]" />
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3 className="font-bold text-xs text-white truncate group-hover:text-[#1FCFAE] transition-colors">
                      {channel.name}
                    </h3>
                    <p className="text-[10px] text-[#A8A6C0]">{channel.groupTitle || 'Geral'}</p>
                  </div>
                </div>

                {/* Program Timeline Chips */}
                <div className="flex-1 overflow-x-auto flex items-center gap-2 pb-1 scrollbar-none">
                  {programs.length > 0 ? (
                    programs.map((prog) => {
                      const active = isNow(prog.startUtc, prog.endUtc);
                      return (
                        <div
                          key={prog.id}
                          onClick={() => setSelectedProgram({ program: prog, channel })}
                          className={`min-w-[200px] max-w-[240px] p-2.5 rounded-xl border transition-all cursor-pointer flex flex-col justify-between shrink-0 ${
                            active
                              ? 'bg-[#6B4FE0]/20 border-[#6B4FE0] text-white shadow-md shadow-[#6B4FE0]/20'
                              : 'bg-[#07070F]/60 hover:bg-[#1E1E38] border-[#2A2A45] text-[#A8A6C0] hover:text-white'
                          }`}
                        >
                          <div>
                            <div className="flex items-center justify-between text-[10px] mb-1">
                              <span className="font-mono font-bold flex items-center gap-1">
                                <Clock className="w-3 h-3 text-[#1FCFAE]" />
                                {formatHour(prog.startUtc)} - {formatHour(prog.endUtc)}
                              </span>
                              {active && (
                                <span className="px-1.5 py-0.2 rounded bg-[#1FCFAE] text-black font-extrabold text-[9px] uppercase">
                                  No Ar
                                </span>
                              )}
                            </div>
                            <h4 className="font-semibold text-xs text-white truncate">
                              {prog.title}
                            </h4>
                          </div>
                          {prog.category && (
                            <span className="text-[10px] text-[#A8A6C0] mt-1 truncate">
                              {prog.category}
                            </span>
                          )}
                        </div>
                      );
                    })
                  ) : (
                    <div className="text-xs text-[#A8A6C0]/60 italic py-2">
                      Sem grade de programação EPG cadastrada para este canal.
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Program Details Modal */}
      {selectedProgram && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-lg bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative animate-in zoom-in-95 duration-150">
            <button
              onClick={() => setSelectedProgram(null)}
              className="absolute top-5 right-5 w-8 h-8 rounded-full bg-[#1E1E38] hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-black/40 p-1 flex items-center justify-center border border-white/10">
                {selectedProgram.channel.logoUrl ? (
                  <img
                    src={selectedProgram.channel.logoUrl}
                    alt={selectedProgram.channel.name}
                    className="max-h-7 max-w-full object-contain"
                  />
                ) : (
                  <Tv className="w-5 h-5 text-[#6B4FE0]" />
                )}
              </div>
              <div>
                <h3 className="font-bold text-sm text-white">{selectedProgram.channel.name}</h3>
                <span className="text-xs text-[#1FCFAE] font-mono">
                  {formatHour(selectedProgram.program.startUtc)} às {formatHour(selectedProgram.program.endUtc)}
                </span>
              </div>
            </div>

            <h2 className="text-lg font-extrabold text-white mb-2">
              {selectedProgram.program.title}
            </h2>

            {selectedProgram.program.category && (
              <span className="inline-block px-2.5 py-1 rounded-lg bg-[#6B4FE0]/20 text-[#6B4FE0] text-xs font-semibold mb-3">
                {selectedProgram.program.category}
              </span>
            )}

            <p className="text-xs text-[#A8A6C0] leading-relaxed mb-6">
              {selectedProgram.program.description ||
                'Nenhuma descrição detalhada fornecida pela emissora.'}
            </p>

            <div className="flex items-center justify-end gap-3 pt-4 border-t border-[#2A2A45]">
              <button
                onClick={() => setSelectedProgram(null)}
                className="px-4 py-2 rounded-xl bg-[#1E1E38] hover:bg-[#2A2A45] text-xs font-semibold text-[#A8A6C0] cursor-pointer"
              >
                Fechar
              </button>
              <button
                onClick={() => {
                  playChannel(selectedProgram.channel);
                  setSelectedProgram(null);
                }}
                className="px-5 py-2 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white text-xs font-bold flex items-center gap-2 cursor-pointer shadow-lg shadow-[#6B4FE0]/40"
              >
                <Play className="w-4 h-4 fill-current" />
                Assistir Canal Agora
              </button>
            </div>
          </div>
        </div>
      )}

      {/* XMLTV Import Modal */}
      {isImportModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-xl bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative">
            <button
              onClick={() => setIsImportModalOpen(false)}
              className="absolute top-5 right-5 w-8 h-8 rounded-full bg-[#1E1E38] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="flex items-center gap-2 mb-2">
              <Upload className="w-5 h-5 text-[#1FCFAE]" />
              <h2 className="text-lg font-bold text-white">Importar Dados XMLTV (EPG)</h2>
            </div>
            <p className="text-xs text-[#A8A6C0] mb-4">
              Carregue um arquivo .xml ou cole o XML com tags &lt;tv&gt;, &lt;channel&gt; e &lt;programme&gt;.
            </p>

            <div className="mb-4">
              <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                Upload de Arquivo XMLTV (.xml)
              </label>
              <input
                type="file"
                accept=".xml,.xmltv"
                onChange={handleFileUpload}
                className="w-full text-xs text-[#A8A6C0] file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-[#6B4FE0] file:text-white hover:file:bg-[#6B4FE0]/80 cursor-pointer"
              />
            </div>

            <div className="mb-4">
              <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                Ou cole o conteúdo XML diretamente:
              </label>
              <textarea
                rows={6}
                value={xmltvInput}
                onChange={(e) => setXmltvInput(e.target.value)}
                placeholder='<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="ch_1"><display-name>NASA TV</display-name></channel>
  <programme start="20261022140000 +0000" stop="20261022150000 +0000" channel="ch_1">
    <title>Espaço & Ciência</title>
  </programme>
</tv>'
                className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl p-3 text-xs text-[#F5F3FF] font-mono outline-none focus:border-[#6B4FE0]"
              />
            </div>

            {importStatus && (
              <div className="p-3 rounded-xl bg-[#6B4FE0]/20 border border-[#6B4FE0]/40 text-xs text-white mb-4">
                {importStatus}
              </div>
            )}

            <div className="flex items-center justify-end gap-3 pt-4 border-t border-[#2A2A45]">
              <button
                onClick={() => setIsImportModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-[#1E1E38] text-xs font-semibold text-[#A8A6C0] cursor-pointer"
              >
                Cancelar
              </button>
              <button
                onClick={handleXmltvImport}
                className="px-5 py-2 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white text-xs font-bold cursor-pointer"
              >
                Processar e Salvar EPG
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
