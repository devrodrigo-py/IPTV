import React from 'react';
import { AlertTriangle, X } from 'lucide-react';

interface ConfirmModalProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  isDestructive?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  title,
  message,
  confirmLabel = 'Confirmar',
  cancelLabel = 'Cancelar',
  isDestructive = false,
  onConfirm,
  onCancel,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 animate-in fade-in duration-150">
      <div className="w-full max-w-md bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative animate-in zoom-in-95 duration-150">
        <button
          onClick={onCancel}
          className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[#1E1E38] text-[#A8A6C0] hover:text-white flex items-center justify-center transition-colors cursor-pointer"
        >
          <X className="w-4 h-4" />
        </button>

        <div className="flex items-center gap-3 mb-3">
          <div
            className={`w-11 h-11 rounded-2xl flex items-center justify-center shrink-0 ${
              isDestructive
                ? 'bg-[#FF5468]/20 text-[#FF5468]'
                : 'bg-[#6B4FE0]/20 text-[#6B4FE0]'
            }`}
          >
            <AlertTriangle className="w-5 h-5" />
          </div>
          <h3 className="text-base font-bold text-white tracking-tight">{title}</h3>
        </div>

        <p className="text-xs text-[#A8A6C0] leading-relaxed mb-6 pl-1">
          {message}
        </p>

        <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-[#2A2A45]/60">
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2.5 rounded-xl bg-[#1E1E38] hover:bg-[#2A2A45] text-xs font-semibold text-[#A8A6C0] hover:text-white transition-colors cursor-pointer"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className={`px-5 py-2.5 rounded-xl text-xs font-bold text-white shadow-lg transition-transform active:scale-95 cursor-pointer ${
              isDestructive
                ? 'bg-[#FF5468] hover:bg-[#FF5468]/85 shadow-[#FF5468]/30'
                : 'bg-[#6B4FE0] hover:bg-[#6B4FE0]/85 shadow-[#6B4FE0]/30'
            }`}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
};
