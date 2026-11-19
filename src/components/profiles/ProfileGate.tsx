import { NebulaLogo } from '../brand/NebulaLogo';
import { AVATAR_PRESETS, Avatar } from './Avatar';
import React, { useState } from 'react';
import { Plus, Lock, Shield, User, X, Check, Edit2, Trash2 } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { UserProfile } from '../../types';

export const ProfileGate: React.FC = () => {
  const { profiles, activeProfile, selectProfile, createProfile, deleteProfile } = useApp();

  const [selectedProfileForPin, setSelectedProfileForPin] = useState<UserProfile | null>(null);
  const [pinAttempt, setPinAttempt] = useState('');
  const [pinError, setPinError] = useState(false);

  // New profile modal
  const [isAddingProfile, setIsAddingProfile] = useState(false);
  const [newName, setNewName] = useState('');
  const [newIsKids, setNewIsKids] = useState(false);
  const [newPin, setNewPin] = useState('');
  const [newAvatar, setNewAvatar] = useState(AVATAR_PRESETS[0]);
  const avatarOptions = AVATAR_PRESETS;

  const handleProfileClick = (profile: UserProfile) => {
    if (profile.pin) {
      setSelectedProfileForPin(profile);
      setPinAttempt('');
      setPinError(false);
    } else {
      selectProfile(profile);
    }
  };

  const handlePinSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProfileForPin) return;

    const ok = selectProfile(selectedProfileForPin, pinAttempt);
    if (ok) {
      setSelectedProfileForPin(null);
    } else {
      setPinError(true);
      setPinAttempt('');
    }
  };

  const handleCreateProfileSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim()) return;

    createProfile({
      name: newName.trim(),
      avatar: newAvatar,
      isKids: newIsKids,
      pin: newPin.trim() || undefined,
    });

    setIsAddingProfile(false);
    setNewName('');
    setNewPin('');
    setNewIsKids(false);
  };

  return (
    <div className="fixed inset-0 z-50 bg-[#060608] flex flex-col items-center justify-center p-6 select-none">
      {/* Return button if already logged into a profile */}
      {activeProfile && !activeProfile.pin && (
        <button
          onClick={() => selectProfile(activeProfile)}
          data-tv-skip
          tabIndex={-1}
          className="absolute top-12 right-14 px-4 py-2 rounded-md text-sm font-medium text-white/50 hover:text-white cursor-pointer transition-colors"
        >
          Voltar ao App
        </button>
      )}

      {/* Brand + title */}
      <div className="absolute top-10 left-14">
        <NebulaLogo size={40} />
      </div>
      <div className="flex flex-col items-center mb-14">
        <h1 className="font-display text-5xl md:text-6xl font-bold text-white tracking-tight">Quem está assistindo?</h1>
      </div>

      {/* Profiles Grid */}
      <div className="flex flex-wrap items-start justify-center gap-10 max-w-6xl">
        {profiles.map((profile, idx) => (
          <div
            key={profile.id}
            tabIndex={0}
            data-autofocus={idx === 0 ? true : undefined}
            data-tv-title={`Perfil: ${profile.name}`}
            onClick={() => handleProfileClick(profile)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') { e.preventDefault(); handleProfileClick(profile); }
            }}
            className="tv-card group flex flex-col items-center cursor-pointer focus:outline-none rounded-xl p-2"
          >
            <div className="relative w-36 h-36 md:w-40 md:h-40 rounded-xl overflow-hidden bg-[#141418]">
              <Avatar avatar={profile.avatar} name={profile.name} className="w-full h-full" textClassName="text-6xl" />

              {/* Pin indicator */}
              {profile.pin && (
                <div className="absolute top-2 right-2 w-7 h-7 rounded-xl bg-black/70 backdrop-blur-md flex items-center justify-center text-white">
                  <Lock className="w-3.5 h-3.5 text-[#FF6F91]" />
                </div>
              )}

              {/* Kids badge */}
              {profile.isKids && (
                <div className="absolute bottom-2 left-2 px-2 py-0.5 rounded-lg bg-[#FF6F91] text-black font-extrabold text-[10px] uppercase">
                  Kids
                </div>
              )}
            </div>

            <span className="text-lg font-medium text-white/60 group-hover:text-white mt-4 text-center transition-colors">
              {profile.name}
            </span>
          </div>
        ))}

        {/* Add Profile Tile */}
        <div
          tabIndex={0}
          data-tv-title="Adicionar Novo Perfil"
          onClick={() => setIsAddingProfile(true)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') { e.preventDefault(); setIsAddingProfile(true); }
          }}
          className="tv-card group flex flex-col items-center cursor-pointer focus:outline-none rounded-xl p-2"
        >
          <div className="w-28 h-28 md:w-32 md:h-32 rounded-3xl border-2 border-dashed border-[#2A2A31] group-hover:border-[#22D3A6] group-hover:scale-105 transition-all flex items-center justify-center bg-[#141418]/30">
            <Plus className="w-10 h-10 text-[#A1A1AA] group-hover:text-[#22D3A6] transition-colors" />
          </div>
          <span className="text-lg font-medium text-white/60 group-hover:text-white mt-4 text-center">
            Adicionar Perfil
          </span>
        </div>
      </div>

      {/* PIN Enter Modal */}
      {selectedProfileForPin && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-[#141418] border border-[#2A2A31] rounded-3xl p-6 shadow-2xl relative text-center">
            <button
              onClick={() => setSelectedProfileForPin(null)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[#1E1E24] text-[#A1A1AA] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="w-14 h-14 rounded-2xl bg-[#FF6F91]/20 text-[#FF6F91] flex items-center justify-center mx-auto mb-3">
              <Lock className="w-7 h-7" />
            </div>

            <h3 className="text-lg font-bold text-white mb-1">
              Perfil Protegido por PIN
            </h3>
            <p className="text-xs text-[#A1A1AA] mb-5">
              Digite a senha de 4 dígitos para acessar o perfil de {selectedProfileForPin.name}.
            </p>

            <form onSubmit={handlePinSubmit} className="space-y-4">
              <input
                type="password"
                maxLength={4}
                autoFocus
                value={pinAttempt}
                onChange={(e) => {
                  setPinAttempt(e.target.value);
                  setPinError(false);
                }}
                placeholder="• • • •"
                className="w-40 mx-auto text-center text-2xl tracking-[0.5em] font-mono bg-[#060608] border border-[#2A2A31] focus:border-[#7C5CFF] rounded-2xl py-3 text-white outline-none"
              />

              {pinError && (
                <p className="text-xs text-[#FF5468] font-semibold">
                  PIN incorreto. Tente novamente.
                </p>
              )}

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setSelectedProfileForPin(null)}
                  className="flex-1 py-2.5 rounded-xl bg-[#1E1E24] text-xs font-semibold text-[#A1A1AA] cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-[#7C5CFF] hover:bg-[#7C5CFF]/80 text-white font-bold text-xs cursor-pointer shadow-lg shadow-[#7C5CFF]/30"
                >
                  Entrar
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create Profile Modal */}
      {isAddingProfile && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-[#141418] border border-[#2A2A31] rounded-3xl p-6 shadow-2xl relative">
            <button
              onClick={() => setIsAddingProfile(false)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[#1E1E24] text-[#A1A1AA] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <h3 className="text-lg font-bold text-white mb-4">Novo Perfil</h3>

            <form onSubmit={handleCreateProfileSubmit} className="space-y-4">
              {/* Select Avatar */}
              <div>
                <label className="block text-xs font-bold text-[#F5F5F7] mb-2">
                  Escolha um Avatar
                </label>
                <div className="flex items-center gap-3">
                  {avatarOptions.map((av) => (
                    <button
                      type="button"
                      key={av}
                      onClick={() => setNewAvatar(av)}
                      data-tv-title="Escolher avatar"
                      className={`tv-card rounded-xl overflow-hidden cursor-pointer transition-all focus:outline-none ${
                        newAvatar === av ? 'ring-2 ring-white scale-110' : 'opacity-60 hover:opacity-100'
                      }`}
                    >
                      <Avatar avatar={av} name={newName || 'N'} className="w-12 h-12" textClassName="text-lg" />
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#F5F5F7] mb-1.5">
                  Nome do Perfil
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Quarto, Filhos, Cinema..."
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full bg-[#060608] border border-[#2A2A31] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#7C5CFF] outline-none"
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl bg-[#060608] border border-[#2A2A31]">
                <div>
                  <p className="text-xs font-bold text-white">Perfil Infantil (Kids)</p>
                  <p className="text-[11px] text-[#A1A1AA]">
                    Filtra automaticamente conteúdos e canais adultos
                  </p>
                </div>
                <input
                  type="checkbox"
                  checked={newIsKids}
                  onChange={(e) => setNewIsKids(e.target.checked)}
                  className="w-5 h-5 accent-[#FF6F91] cursor-pointer"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#F5F5F7] mb-1.5">
                  PIN de Bloqueio (Opcional - 4 dígitos)
                </label>
                <input
                  type="password"
                  maxLength={4}
                  placeholder="Ex: 1234"
                  value={newPin}
                  onChange={(e) => setNewPin(e.target.value)}
                  className="w-full bg-[#060608] border border-[#2A2A31] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#7C5CFF] outline-none font-mono"
                />
              </div>

              <div className="flex gap-2 pt-3 border-t border-[#2A2A31]">
                <button
                  type="button"
                  onClick={() => setIsAddingProfile(false)}
                  className="flex-1 py-2.5 rounded-xl bg-[#1E1E24] text-xs font-semibold text-[#A1A1AA] cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-[#7C5CFF] hover:bg-[#7C5CFF]/80 text-white font-bold text-xs cursor-pointer shadow-lg shadow-[#7C5CFF]/30"
                >
                  Criar Perfil
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
