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
  const { filteredChannels } = useApp();

  const [layoutMode, setLayoutMode] = useState<2 | 4 | 9>(4);
  const [activeAudioSlot, setActiveAudioSlot] = useState<number>(0);
  const [slots, setSlots] = useState<(Channel | null)[]>([
    filteredChannels[0] || null,
    filteredChannels[1] || null,
    filteredChannels[2] || null,
    filteredChannels[3] || null,
  ]);
  const [pickingSlotIndex, setPickingSlotIndex] = useState<number | null>(null);

  const changeLayout = (mode: 2 | 4 | 9) => {
    setLayoutMode(mode);
    setSlots((prev) => {
      const next = [...prev];
      while (next.length < mode) {
        const nextChannel = filteredChannels[next.length % filteredChannels.length] || null;
        next.push(nextChannel);
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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#2A2A45]">
        <div>
          <div className="flex items-center gap-2">
            <LayoutGrid className="w-5 h-5 text-[#1FCFAE]" />
            <h1 className="text-xl font-bold text-white tracking-tight">Multiview Grid</h1>
          </div>
          <p className="text-xs text-[#A8A6C0] mt-0.5">
            Monitore múltiplos canais ao mesmo tempo. Clique no ícone de som para ouvir o áudio do canal desejado.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-[#A8A6C0] font-medium mr-1">Telas:</span>
          <button
            onClick={() => changeLayout(2)}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 2
                ? 'bg-[#6B4FE0] text-white border-[#6B4FE0]'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border-[#2A2A45]'
            }`}
          >
            2 Telas
          </button>
          <button
            onClick={() => changeLayout(4)}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 4
                ? 'bg-[#6B4FE0] text-white border-[#6B4FE0]'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border-[#2A2A45]'
            }`}
          >
            4 Telas (2x2)
          </button>
          <button
            onClick={() => changeLayout(9)}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all border ${
              layoutMode === 9
                ? 'bg-[#6B4FE0] text-white border-[#6B4FE0]'
                : 'bg-[#16162A] text-[#A8A6C0] hover:text-white border-[#2A2A45]'
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
              className="relative bg-[#07070F] rounded-2xl border border-[#2A2A45] overflow-hidden flex items-center justify-center group"
            >
              {/* Empty Slot */}
              <button
                onClick={() => setPickingSlotIndex(idx)}
                className="flex flex-col items-center justify-center p-6 text-center hover:scale-105 transition-transform cursor-pointer"
              >
                <div className="w-12 h-12 rounded-2xl bg-[#16162A] border border-[#2A2A45] flex items-center justify-center text-[#6B4FE0] mb-3 group-hover:bg-[#6B4FE0] group-hover:text-white transition-colors">
                  <Plus className="w-6 h-6" />
                </div>
                <span className="text-xs font-bold text-white">Adicionar Canal ao Slot {idx + 1}</span>
                <span className="text-[11px] text-[#A8A6C0] mt-0.5">Clique para selecionar</span>
              </button>
            </div>
          );
        })}
      </div>

      {/* Channel Picker Modal */}
      {pickingSlotIndex !== null && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-lg bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl flex flex-col max-h-[80vh]">
            <div className="flex items-center justify-between pb-4 border-b border-[#2A2A45]">
              <div className="flex items-center gap-2">
                <Tv className="w-5 h-5 text-[#6B4FE0]" />
                <h3 className="font-bold text-white text-base">
                  Selecionar Canal para o Slot {pickingSlotIndex + 1}
                </h3>
              </div>
              <button
                onClick={() => setPickingSlotIndex(null)}
                className="w-8 h-8 rounded-lg hover:bg-[#2A2A45] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto py-3 space-y-2 mt-2">
              {filteredChannels.map((channel) => (
                <div
                  key={channel.id}
                  onClick={() => assignChannelToSlot(channel)}
                  className="p-3 rounded-xl bg-[#07070F] hover:bg-[#1E1E38] border border-[#2A2A45] hover:border-[#6B4FE0] flex items-center justify-between cursor-pointer transition-all"
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
                      <div className="w-8 h-8 rounded bg-[#2A2A45] flex items-center justify-center text-white">
                        <Tv className="w-4 h-4" />
                      </div>
                    )}
                    <div>
                      <h4 className="text-xs font-bold text-white">{channel.name}</h4>
                      <p className="text-[10px] text-[#A8A6C0]">{channel.groupTitle || 'Geral'}</p>
                    </div>
                  </div>
                  {channel.resolution && (
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-[#1FCFAE]/20 text-[#1FCFAE]">
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
