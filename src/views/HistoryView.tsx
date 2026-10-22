import React from 'react';
import { History, Trash2, Play, Tv, Film } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const HistoryView: React.FC = () => {
  const { history, clearHistory, filteredChannels, vodItems, playChannel, playVod } = useApp();

  return (
    <div className="px-6 md:px-12 py-8 max-w-[1920px] mx-auto space-y-6 select-none">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <History className="w-5 h-5 text-[#6B4FE0]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Histórico de Visualização</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Registro dos canais, filmes e séries reproduzidos recentemente.
          </p>
        </div>

        {history.length > 0 && (
          <button
            onClick={clearHistory}
            className="px-4 py-2 rounded-xl bg-[#16162A] hover:bg-[#FF5468]/20 border border-[#2A2A45] hover:border-[#FF5468]/50 text-xs font-semibold text-[#A8A6C0] hover:text-[#FF5468] flex items-center gap-2 transition-all cursor-pointer"
          >
            <Trash2 className="w-3.5 h-3.5" />
            Limpar Histórico
          </button>
        )}
      </div>

      {history.length > 0 ? (
        <div className="space-y-3">
          {history.map((item) => (
            <div
              key={item.id}
              tabIndex={0}
              data-tv-title={`Histórico: ${item.title}`}
              onClick={() => {
                const ch = filteredChannels.find((c) => c.id === item.contentId);
                if (ch) playChannel(ch);
                else if (item.contentType === 'vod') {
                  const vod = vodItems.find((v) => v.id === item.contentId);
                  if (vod) playVod(vod);
                }
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  const ch = filteredChannels.find((c) => c.id === item.contentId);
                  if (ch) playChannel(ch);
                  else if (item.contentType === 'vod') {
                    const vod = vodItems.find((v) => v.id === item.contentId);
                    if (vod) playVod(vod);
                  }
                }
              }}
              className="tv-card p-4 rounded-2xl bg-[#16162A] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] flex items-center justify-between cursor-pointer transition-all shadow-sm group focus:outline-none"
            >
              <div className="flex items-center gap-4 min-w-0 flex-1">
                <div className="w-14 h-14 rounded-xl bg-black/40 overflow-hidden relative shrink-0 flex items-center justify-center border border-white/5">
                  {item.posterUrl ? (
                    <img
                      src={item.posterUrl}
                      alt={item.title}
                      className="w-full h-full object-contain p-1"
                    />
                  ) : item.contentType === 'vod' ? (
                    <Film className="w-6 h-6 text-[#6B4FE0]" />
                  ) : (
                    <Tv className="w-6 h-6 text-[#6B4FE0]" />
                  )}
                  <div className="absolute inset-0 bg-[#6B4FE0]/60 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity">
                    <Play className="w-5 h-5 text-white fill-current" />
                  </div>
                </div>

                <div className="min-w-0 flex-1 pr-4">
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-sm text-white truncate group-hover:text-[#1FCFAE]">
                      {item.title}
                    </h3>
                    <span className="text-[10px] uppercase font-bold px-1.5 py-0.2 rounded bg-black/40 text-[#6B4FE0]">
                      {item.contentType}
                    </span>
                  </div>
                  <p className="text-xs text-[#A8A6C0] truncate mt-0.5">
                    {item.subtitle || 'Transmissão Ao Vivo'}
                  </p>
                  <span className="text-[10px] text-[#A8A6C0]/70 font-mono mt-1 block">
                    {new Date(item.timestamp).toLocaleString()}
                  </span>
                </div>
              </div>

              <button className="w-10 h-10 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white flex items-center justify-center transition-transform group-hover:scale-105 cursor-pointer">
                <Play className="w-4 h-4 fill-current ml-0.5" />
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="p-16 text-center bg-[#16162A]/40 rounded-3xl border border-[#2A2A45] mt-6">
          <History className="w-14 h-14 text-[#6B4FE0]/40 mx-auto mb-3" />
          <h3 className="text-base font-bold text-white">Nenhum histórico recente</h3>
          <p className="text-xs text-[#A8A6C0] mt-1">
            Os conteúdos que você reproduzir aparecerão aqui automaticamente.
          </p>
        </div>
      )}
    </div>
  );
};
