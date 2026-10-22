import React, { useState } from 'react';
import { Plus, Lock, Shield, User, X, Check, Edit2, Trash2 } from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { UserProfile } from '../../types';

export const ProfileGate: React.FC = () => {
  const { profiles, selectProfile, createProfile, deleteProfile } = useApp();

  const [selectedProfileForPin, setSelectedProfileForPin] = useState<UserProfile | null>(null);
  const [pinAttempt, setPinAttempt] = useState('');
  const [pinError, setPinError] = useState(false);

  // New profile modal
  const [isAddingProfile, setIsAddingProfile] = useState(false);
  const [newName, setNewName] = useState('');
  const [newIsKids, setNewIsKids] = useState(false);
  const [newPin, setNewPin] = useState('');
  const [newAvatar, setNewAvatar] = useState('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80');

  const avatarOptions = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  ];

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
    <div className="fixed inset-0 z-50 bg-[#07070F] flex flex-col items-center justify-center p-6 select-none">
      {/* Brand Icon Header */}
      <div className="flex flex-col items-center mb-10">
        <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-[#6B4FE0] via-[#2A1D6B] to-[#1FCFAE] p-2 flex items-center justify-center shadow-xl shadow-[#6B4FE0]/30 mb-3">
          <img
            src="/assets/branding/nebula_icon.png"
            alt="Nebula"
            className="w-full h-full object-contain filter drop-shadow"
            onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }}
          />
        </div>
        <h1 className="text-3xl font-extrabold text-white tracking-tight font-['Outfit']">
          Quem está assistindo?
        </h1>
        <p className="text-xs text-[#A8A6C0] mt-1">
          Escolha um perfil para carregar preferências, favoritos e histórico.
        </p>
      </div>

      {/* Profiles Grid */}
      <div className="flex flex-wrap items-center justify-center gap-6 max-w-4xl">
        {profiles.map((profile) => (
          <div
            key={profile.id}
            onClick={() => handleProfileClick(profile)}
            className="group flex flex-col items-center cursor-pointer"
          >
            <div className="relative w-28 h-28 md:w-32 md:h-32 rounded-3xl overflow-hidden border-2 border-transparent group-hover:border-[#6B4FE0] group-hover:scale-105 group-hover:shadow-2xl group-hover:shadow-[#6B4FE0]/40 transition-all duration-300 bg-[#16162A]">
              <img
                src={profile.avatar}
                alt={profile.name}
                className="w-full h-full object-cover"
              />

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

            <span className="text-sm font-bold text-[#A8A6C0] group-hover:text-white mt-3 text-center transition-colors">
              {profile.name}
            </span>
          </div>
        ))}

        {/* Add Profile Tile */}
        <div
          onClick={() => setIsAddingProfile(true)}
          className="group flex flex-col items-center cursor-pointer"
        >
          <div className="w-28 h-28 md:w-32 md:h-32 rounded-3xl border-2 border-dashed border-[#2A2A45] group-hover:border-[#1FCFAE] group-hover:scale-105 transition-all flex items-center justify-center bg-[#16162A]/30">
            <Plus className="w-10 h-10 text-[#A8A6C0] group-hover:text-[#1FCFAE] transition-colors" />
          </div>
          <span className="text-sm font-bold text-[#A8A6C0] group-hover:text-white mt-3 text-center">
            Adicionar Perfil
          </span>
        </div>
      </div>

      {/* PIN Enter Modal */}
      {selectedProfileForPin && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="w-full max-w-sm bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative text-center">
            <button
              onClick={() => setSelectedProfileForPin(null)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[#1E1E38] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="w-14 h-14 rounded-2xl bg-[#FF6F91]/20 text-[#FF6F91] flex items-center justify-center mx-auto mb-3">
              <Lock className="w-7 h-7" />
            </div>

            <h3 className="text-lg font-bold text-white mb-1">
              Perfil Protegido por PIN
            </h3>
            <p className="text-xs text-[#A8A6C0] mb-5">
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
                className="w-40 mx-auto text-center text-2xl tracking-[0.5em] font-mono bg-[#07070F] border border-[#2A2A45] focus:border-[#6B4FE0] rounded-2xl py-3 text-white outline-none"
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
                  className="flex-1 py-2.5 rounded-xl bg-[#1E1E38] text-xs font-semibold text-[#A8A6C0] cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs cursor-pointer shadow-lg shadow-[#6B4FE0]/30"
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
          <div className="w-full max-w-md bg-[#16162A] border border-[#2A2A45] rounded-3xl p-6 shadow-2xl relative">
            <button
              onClick={() => setIsAddingProfile(false)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[#1E1E38] text-[#A8A6C0] hover:text-white flex items-center justify-center cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>

            <h3 className="text-lg font-bold text-white mb-4">Novo Perfil</h3>

            <form onSubmit={handleCreateProfileSubmit} className="space-y-4">
              {/* Select Avatar */}
              <div>
                <label className="block text-xs font-bold text-[#F5F3FF] mb-2">
                  Escolha um Avatar
                </label>
                <div className="flex items-center gap-3">
                  {avatarOptions.map((av) => (
                    <img
                      key={av}
                      src={av}
                      alt="Avatar"
                      onClick={() => setNewAvatar(av)}
                      className={`w-12 h-12 rounded-xl object-cover cursor-pointer transition-all ${
                        newAvatar === av
                          ? 'border-2 border-[#6B4FE0] scale-110'
                          : 'opacity-60 hover:opacity-100'
                      }`}
                    />
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                  Nome do Perfil
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Quarto, Filhos, Cinema..."
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none"
                />
              </div>

              <div className="flex items-center justify-between p-3 rounded-xl bg-[#07070F] border border-[#2A2A45]">
                <div>
                  <p className="text-xs font-bold text-white">Perfil Infantil (Kids)</p>
                  <p className="text-[11px] text-[#A8A6C0]">
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
                <label className="block text-xs font-bold text-[#F5F3FF] mb-1.5">
                  PIN de Bloqueio (Opcional - 4 dígitos)
                </label>
                <input
                  type="password"
                  maxLength={4}
                  placeholder="Ex: 1234"
                  value={newPin}
                  onChange={(e) => setNewPin(e.target.value)}
                  className="w-full bg-[#07070F] border border-[#2A2A45] rounded-xl px-3.5 py-2.5 text-xs text-white focus:border-[#6B4FE0] outline-none font-mono"
                />
              </div>

              <div className="flex gap-2 pt-3 border-t border-[#2A2A45]">
                <button
                  type="button"
                  onClick={() => setIsAddingProfile(false)}
                  className="flex-1 py-2.5 rounded-xl bg-[#1E1E38] text-xs font-semibold text-[#A8A6C0] cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-[#6B4FE0] hover:bg-[#6B4FE0]/80 text-white font-bold text-xs cursor-pointer shadow-lg shadow-[#6B4FE0]/30"
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
