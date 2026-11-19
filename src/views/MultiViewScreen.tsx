import React, { useState } from 'react';
import {
  LayoutGrid,
  Volume2,
  VolumeX,
  Plus,
  Maximize2,
  Tv,
  X,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Channel } from '../types';
import { MultiViewTile } from '../components/multiview/MultiViewTile';

export const MultiViewScreen: React.FC = () => {
  const { filteredChannels, deviceProfile } = useApp();
  const maxTiles = deviceProfile.maxMultiviewTiles;
  const [pickerQuery, setPickerQuery] = useState('');
  const pickerChannels = (pickerQuery.trim()
    ? filteredChannels.filter((c) => c.name.toLowerCase().includes(pickerQuery.trim().toLowerCase()))
    : filteredChannels
  ).slice(0, 150);

  const [layoutMode, setLayoutMode] = useState<2 | 4 | 9>(() => (maxTiles >= 4 ? 4 : 2));
  const [activeAudioSlot, setActiveAudioSlot] = useState<number>(0);
  // Slots start empty: decoding several streams at once is heavy on TV sticks.
  const [slots, setSlots] = useState<(Channel | null)[]>(() => Array(maxTiles >= 4 ? 4 : 2).fill(null));
  const [pickingSlotIndex, setPickingSlotIndex] = useState<number | null>(null);

  const changeLayout = (mode: 2 | 4 | 9) => {
    setLayoutMode(mode);
    setSlots((prev) => {
      const next = [...prev];
      while (next.length < mode) {
        next.push(null);
      }
      return next.slice(0, mode);
    });
  };

  const assignChannelToSlot = (channel: Channel) => {
    if (pickingSlotIndex !== null) {
      setSlots((prev) => {
        const next = [...prev];
        next[pickingSlotIndex] = channel;
        return next;
      });
      setPickingSlotIndex(null);
    }
  };

  const removeSlotChannel = (index: number) => {
    setSlots((prev) => {
      const next = [...prev];
      next[index] = null;
      return next;
    });
  };

  return (
    <div className="px-6 md:px-12 py-8 h-[calc(100vh-4rem)] flex flex-col select-none">
      {/* Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="font-display text-4xl font-bold text-white tracking-tight">Multitela</h1>
          </div>
          <p className="text-base text-white/50 mt-1.5">
            Monitore múltiplos canais ao mesmo tempo. Clique no ícone de som para ouvir o áudio do canal desejado.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-[#A1A1AA] font-medium mr-1">Telas:</span>
          <button
            onClick={() => changeLayout(2)}
            disabled={2 > maxTiles}
            title={2 > maxTiles ? 'Este aparelho não decodifica tantas transmissões ao mesmo tempo' : undefined}
            data-tv-title="2 Telas"
            className={`tv-card focus:outline-none disabled:opacity-30 disabled:cursor-not-allowed px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 2
                ? 'bg-[#7C5CFF] text-white border-[#7C5CFF]'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border-[#2A2A31]'
            }`}
          >
            2 Telas
          </button>
          <button
            onClick={() => changeLayout(4)}
            disabled={4 > maxTiles}
            title={4 > maxTiles ? 'Este aparelho não decodifica tantas transmissões ao mesmo tempo' : undefined}
            data-tv-title="4 Telas (2x2)"
            className={`tv-card focus:outline-none disabled:opacity-30 disabled:cursor-not-allowed px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 4
                ? 'bg-[#7C5CFF] text-white border-[#7C5CFF]'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border-[#2A2A31]'
            }`}
          >
            4 Telas (2x2)
          </button>
          <button
            onClick={() => changeLayout(9)}
            disabled={9 > maxTiles}
            title={9 > maxTiles ? 'Este aparelho não decodifica tantas transmissões ao mesmo tempo' : undefined}
            data-tv-title="9 Telas (3x3)"
            className={`tv-card focus:outline-none disabled:opacity-30 disabled:cursor-not-allowed px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 9
                ? 'bg-[#7C5CFF] text-white border-[#7C5CFF]'
                : 'bg-[#141418] text-[#A1A1AA] hover:text-white border-[#2A2A31]'
            }`}
          >
            9 Telas (3x3)
          </button>
        </div>
      </div>

      {/* Grid Container */}
      <div
        className={`flex-1 grid gap-3 mt-4 min-h-0 ${
          layoutMode === 2
            ? 'grid-cols-1 md:grid-cols-2'
            : layoutMode === 4
            ? 'grid-cols-2 grid-rows-2'
            : 'grid-cols-3 grid-rows-3'
        }`}
      >
        {slots.map((channel, idx) => {
          const isAudible = activeAudioSlot === idx;

          if (channel) {
            return (
              <MultiViewTile
                key={idx}
                index={idx}
                channel={channel}
                isAudible={isAudible}
                onToggleAudio={() => setActiveAudioSlot(isAudible ? -1 : idx)}
                onChangeChannel={() => setPickingSlotIndex(idx)}
                onRemoveChannel={() => removeSlotChannel(idx)}
              />
            );
          }

          return (
            <div
              key={idx}
              className="relative bg-[#060608] rounded-2xl border border-[#2A2A31] overflow-hidden flex items-center justify-center group"
            >
              {/* Empty Slot */}
              <button
                onClick={() => setPickingSlotIndex(idx)}
                className="flex flex-col items-center justify-center p-6 text-center hover:scale-105 transition-transform cursor-pointer"
              >
                <div className="w-12 h-12 rounded-2xl bg-[#141418] border border-[#2A2A31] flex items-center justify-center text-[#7C5CFF] mb-3 group-hover:bg-[#7C5CFF] group-hover:text-white transition-colors">
                  <Plus className="w-6 h-6" />
                </div>
                <span className="text-xs font-bold text-white">Adicionar Canal ao Slot {idx + 1}</span>
                <span className="text-[11px] text-[#A1A1AA] mt-0.5">Clique para selecionar</span>
              </button>
            </div>
          );
        })}
      </div>

      {/* Channel Picker Modal */}
      {pickingSlotIndex !== null && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-lg bg-[#141418] border border-[#2A2A31] rounded-3xl p-6 shadow-2xl flex flex-col max-h-[80vh]">
            <div className="flex items-center justify-between pb-6">
              <div className="flex items-center gap-2">
                <Tv className="w-5 h-5 text-[#7C5CFF]" />
                <h3 className="font-bold text-white text-base">
                  Selecionar Canal para o Slot {pickingSlotIndex + 1}
                </h3>
              </div>
              <button
                onClick={() => setPickingSlotIndex(null)}
                className="w-8 h-8 rounded-lg hover:bg-[#2A2A31] text-[#A1A1AA] hover:text-white flex items-center justify-center cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <input
              type="text"
              value={pickerQuery}
              onChange={(e) => setPickerQuery(e.target.value)}
              placeholder="Buscar canal…"
              className="mt-3 bg-[#060608] border border-[#2A2A31] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#7C5CFF]"
            />
            <div className="flex-1 overflow-y-auto py-3 space-y-2 mt-2">
              {pickerChannels.map((channel) => (
                <div
                  key={channel.id}
                  tabIndex={0}
                  data-tv-title={`Colocar ${channel.name}`}
                  onClick={() => assignChannelToSlot(channel)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      assignChannelToSlot(channel);
                    }
                  }}
                  className="tv-card focus:outline-none p-3 rounded-xl bg-[#060608] hover:bg-[#1E1E24] border border-[#2A2A31] hover:border-[#7C5CFF] flex items-center justify-between cursor-pointer transition-all"
                >
                  <div className="flex items-center gap-3">
                    {channel.logoUrl ? (
                      <img
                        src={channel.logoUrl}
                        alt={channel.name}
                        className="w-8 h-8 object-contain rounded bg-black/40 p-1"
                        onError={(e) => ((e.target as HTMLElement).style.display = 'none')}
                      />
                    ) : (
                      <div className="w-8 h-8 rounded bg-[#2A2A31] flex items-center justify-center text-white">
                        <Tv className="w-4 h-4" />
                      </div>
                    )}
                    <div>
                      <h4 className="text-xs font-bold text-white">{channel.name}</h4>
                      <p className="text-[10px] text-[#A1A1AA]">{channel.groupTitle || 'Geral'}</p>
                    </div>
                  </div>
                  {channel.resolution && (
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-[#22D3A6]/20 text-[#22D3A6]">
                      {channel.resolution}
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
