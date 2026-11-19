import React, { useEffect, useState, useRef, useCallback } from 'react';
import {
  ChevronUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Circle,
  CornerUpLeft,
  Tv,
  X,
  Volume2,
  VolumeX,
  Play,
  Pause,
  FastForward,
  Rewind,
  Home,
  Menu,
  Mic,
  Maximize2,
  Sparkles,
  Zap,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';
import { EXIT_EVENT } from '../../platform/useNativeBridge';
import { isNativeApp } from '../../platform/platform';

export const TvRemoteOverlay: React.FC = () => {
  const {
    tvMode,
    toggleTvMode,
    isPlayerOpen,
    closePlayer,
    activeTab,
    setActiveTab,
    currentStream,
    filteredChannels,
    playChannel,
    selectedVodModal,
    setSelectedVodModal,
    selectedSeriesModal,
    setSelectedSeriesModal,
    deviceProfile,
    isHydrated,
  } = useApp();

  const [isRemoteVisible, setIsRemoteVisible] = useState(false);
  const [lastKeyPressed, setLastKeyPressed] = useState<string>('Nenhuma');
  const [focusedElementTitle, setFocusedElementTitle] = useState<string>('Página Inicial');
  const [isAutoTourRunning, setIsAutoTourRunning] = useState(false);
  const autoTourTimeouts = useRef<NodeJS.Timeout[]>([]);
  const lastTriggerRef = useRef<HTMLElement | null>(null);

  // Find all focusable TV elements currently in DOM
  const getFocusableElements = useCallback((): HTMLElement[] => {
    const selector =
      'button, a[href], input, select, textarea, [tabindex]:not([tabindex="-1"]), .tv-card, .tv-focusable';
    const all = Array.from(document.querySelectorAll<HTMLElement>(selector));

    return all.filter((el) => {
      // Must be visible, enabled and not explicitly excluded from remote focus
      if (el.hasAttribute('disabled')) return false;
      if (el.getAttribute('tabindex') === '-1' || el.hasAttribute('data-tv-skip')) return false;
      const style = window.getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') {
        return false;
      }
      const rect = el.getBoundingClientRect();
      return rect.width > 0 && rect.height > 0;
    });
  }, []);

  // Update focused element visual state & title with safe 10-foot TV margins
  const applyTvFocus = useCallback((el: HTMLElement) => {
    // Clear previous
    document.querySelectorAll('.tv-focused').forEach((prev) => {
      prev.classList.remove('tv-focused');
    });

    el.classList.add('tv-focused');
    el.focus({ preventScroll: true });

    // TV-safe auto-scroll: prevent sticky navbar or viewport edges from obscuring the focused card
    const mainContainer = document.querySelector('main');
    if (mainContainer && mainContainer.contains(el)) {
      const elRect = el.getBoundingClientRect();
      const mainRect = mainContainer.getBoundingClientRect();

      if (elRect.top < mainRect.top + 80) {
        mainContainer.scrollBy({ top: elRect.top - mainRect.top - 100, behavior: 'smooth' });
      } else if (elRect.bottom > mainRect.bottom - 80) {
        mainContainer.scrollBy({ top: elRect.bottom - mainRect.bottom + 100, behavior: 'smooth' });
      }
    } else {
      el.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'nearest' });
    }

    // Derive readable title for HUD
    const customTitle =
      el.getAttribute('data-tv-title') ||
      el.getAttribute('aria-label') ||
      el.getAttribute('title') ||
      el.innerText?.split('\n')[0]?.slice(0, 32) ||
      el.tagName;

    setFocusedElementTitle(customTitle);
  }, []);

  // 2D Spatial Navigation Algorithm with Strict Row & Column Affinity (Netflix / HBO Max Standard)
  const navigateDirectional = useCallback(
    (direction: 'up' | 'down' | 'left' | 'right') => {
      const focusables = getFocusableElements();
      if (focusables.length === 0) return;

      const active = (document.activeElement as HTMLElement) || focusables[0];
      const isInSidebar = !!active.closest('aside');

      // Netflix pattern: When in Sidebar and user presses RIGHT, jump straight to the first visible card in Main
      if (isInSidebar && direction === 'right') {
        const firstMainTarget = document.querySelector<HTMLElement>('main .tv-card, main button, main input');
        if (firstMainTarget) {
          applyTvFocus(firstMainTarget);
          return;
        }
      }

      const currentRect = active.getBoundingClientRect();
      const currentCenter = {
        x: currentRect.left + currentRect.width / 2,
        y: currentRect.top + currentRect.height / 2,
      };

      let candidates: { el: HTMLElement; distance: number }[] = [];

      focusables.forEach((el) => {
        if (el === active) return;
        // Don't jump into remote overlay itself unless explicitly clicked
        if (el.closest('.tv-remote-widget')) return;

        const rect = el.getBoundingClientRect();
        const center = {
          x: rect.left + rect.width / 2,
          y: rect.top + rect.height / 2,
        };

        const dx = center.x - currentCenter.x;
        const dy = center.y - currentCenter.y;

        let isValid = false;
        let weightedDistance = Infinity;

        if (direction === 'right') {
          // Must be to the right (centers: the focused card is scaled up)
          if (dx > Math.min(currentRect.width, rect.width) * 0.5) {
            isValid = true;
            const horizontalGap = Math.max(0, rect.left - currentRect.right);
            const verticalDist = Math.abs(dy);
            const verticalOverlap = Math.max(0, Math.min(rect.bottom, currentRect.bottom) - Math.max(rect.top, currentRect.top));
            const isSameRow = verticalOverlap > 0 || verticalDist < 40;

            // Row-lock: severely penalize candidates in different rows to preserve horizontal carousels
            weightedDistance = horizontalGap * 1.0 + verticalDist * 1.5 + (isSameRow ? 0 : 800);
          }
        } else if (direction === 'left') {
          // Must be to the left (centers: the focused card is scaled up)
          if (-dx > Math.min(currentRect.width, rect.width) * 0.5) {
            isValid = true;
            const horizontalGap = Math.max(0, currentRect.left - rect.right);
            const verticalDist = Math.abs(dy);
            const verticalOverlap = Math.max(0, Math.min(rect.bottom, currentRect.bottom) - Math.max(rect.top, currentRect.top));
            const isSameRow = verticalOverlap > 0 || verticalDist < 40;

            weightedDistance = horizontalGap * 1.0 + verticalDist * 1.5 + (isSameRow ? 0 : 800);
          }
        } else if (direction === 'down') {
          // Must be below. Centers are compared because the focused card is
          // scaled up, which would make same-row neighbours look "lower".
          if (dy > Math.min(currentRect.height, rect.height) * 0.5) {
            isValid = true;
            const verticalGap = Math.max(0, rect.top - currentRect.bottom);
            const horizontalDist = Math.abs(dx);
            const horizontalOverlap = Math.max(0, Math.min(rect.right, currentRect.right) - Math.max(rect.left, currentRect.left));
            const isSameColumn = horizontalOverlap > 0 || horizontalDist < 50;

            // Column-lock: prioritize items directly below
            weightedDistance = verticalGap * 1.0 + horizontalDist * 1.5 + (isSameColumn ? 0 : 400);
          }
        } else if (direction === 'up') {
          // Must be above (see note on scaling above)
          if (-dy > Math.min(currentRect.height, rect.height) * 0.5) {
            isValid = true;
            const verticalGap = Math.max(0, currentRect.top - rect.bottom);
            const horizontalDist = Math.abs(dx);
            const horizontalOverlap = Math.max(0, Math.min(rect.right, currentRect.right) - Math.max(rect.left, currentRect.left));
            const isSameColumn = horizontalOverlap > 0 || horizontalDist < 50;

            weightedDistance = verticalGap * 1.0 + horizontalDist * 1.5 + (isSameColumn ? 0 : 400);
          }
        }

        if (isValid) {
          candidates.push({ el, distance: weightedDistance });
        }
      });

      if (candidates.length > 0 && (direction === 'up' || direction === 'down')) {
        // Row-first (streaming-app style): go to the nearest row, then to the
        // card in that row closest to the current horizontal position.
        const gapOf = (el: HTMLElement) => {
          const r = el.getBoundingClientRect();
          return direction === 'down' ? Math.max(0, r.top - currentRect.bottom) : Math.max(0, currentRect.top - r.bottom);
        };
        // Up/Down never cross between the menu rail and the content.
        const sameRegion = candidates.filter((c) => !!c.el.closest('aside') === isInSidebar);
        if (sameRegion.length === 0) return;
        const minGap = Math.min(...sameRegion.map((c) => gapOf(c.el)));
        const row = sameRegion.filter((c) => gapOf(c.el) <= minGap + 24);
        row.sort((a, b) => {
          const ra = a.el.getBoundingClientRect();
          const rb = b.el.getBoundingClientRect();
          return Math.abs(ra.left + ra.width / 2 - currentCenter.x) - Math.abs(rb.left + rb.width / 2 - currentCenter.x);
        });
        applyTvFocus(row[0].el);
      } else if (candidates.length > 0) {
        candidates.sort((a, b) => a.distance - b.distance);
        const best = candidates[0].el;
        // Entering the menu from the content lands on the current screen's item.
        if (direction === 'left' && !isInSidebar && best.closest('aside')) {
          applyTvFocus(document.querySelector<HTMLElement>('aside nav button[data-active="true"]') || best);
        } else {
          applyTvFocus(best);
        }
      } else {
        // Netflix signature edge transition:
        // When pressing LEFT from the leftmost item of any content view, smoothly slide focus into the Sidebar
        if (direction === 'left' && !isInSidebar) {
          const activeSidebarBtn =
            document.querySelector<HTMLElement>('aside nav button[data-active="true"]') ||
            document.querySelector<HTMLElement>('aside nav button');
          if (activeSidebarBtn) {
            applyTvFocus(activeSidebarBtn);
          }
        }
      }
    },
    [getFocusableElements, applyTvFocus]
  );

  // Central OK / Select Action with Memory Retention
  const triggerSelect = useCallback(() => {
    const active = document.activeElement as HTMLElement;
    if (active) {
      lastTriggerRef.current = active;
      if (typeof active.click === 'function') {
        active.click();
        setLastKeyPressed('OK / SELECT');
      }
    }
  }, []);

  // Back Button Action (Strict Netflix / HBO Max Hierarchy & Focus Restoration)
  const triggerBack = useCallback(() => {
    setLastKeyPressed('VOLTAR (BACK)');

    // 1. If Video Player is open -> close player and restore focus to the channel/movie that triggered it
    if (isPlayerOpen) {
      closePlayer();
      setTimeout(() => {
        if (lastTriggerRef.current && document.body.contains(lastTriggerRef.current)) {
          applyTvFocus(lastTriggerRef.current);
        } else {
          const firstCard = document.querySelector<HTMLElement>('main .tv-card');
          if (firstCard) applyTvFocus(firstCard);
        }
      }, 150);
      return;
    }

    // 2. If VOD modal is open -> close modal and restore focus to that specific movie card
    if (selectedVodModal) {
      setSelectedVodModal(null);
      setTimeout(() => {
        if (lastTriggerRef.current && document.body.contains(lastTriggerRef.current)) {
          applyTvFocus(lastTriggerRef.current);
        } else {
          const firstCard = document.querySelector<HTMLElement>('main .tv-card');
          if (firstCard) applyTvFocus(firstCard);
        }
      }, 150);
      return;
    }

    // 3. If Series modal is open -> close modal and restore focus to that specific series card
    if (selectedSeriesModal) {
      setSelectedSeriesModal(null);
      setTimeout(() => {
        if (lastTriggerRef.current && document.body.contains(lastTriggerRef.current)) {
          applyTvFocus(lastTriggerRef.current);
        } else {
          const firstCard = document.querySelector<HTMLElement>('main .tv-card');
          if (firstCard) applyTvFocus(firstCard);
        }
      }, 150);
      return;
    }

    // 4. If in Search tab -> return to Home and focus first card
    if (activeTab === 'search') {
      setActiveTab('home');
      setTimeout(() => {
        const firstCard = document.querySelector<HTMLElement>('main .tv-card');
        if (firstCard) applyTvFocus(firstCard);
      }, 150);
      return;
    }

    // 5a. Screens opened from "Mais" go back to "Mais".
    if (['playlists', 'favorites', 'history', 'multiview', 'stats', 'settings'].includes(activeTab)) {
      setActiveTab('more');
      return;
    }

    // 5. If in any other subpage (Canais, VOD, Séries, Favoritos, Histórico, EPG, etc.) -> return to Home
    if (activeTab !== 'home') {
      setActiveTab('home');
      setTimeout(() => {
        const firstCard = document.querySelector<HTMLElement>('main .tv-card');
        if (firstCard) applyTvFocus(firstCard);
      }, 150);
      return;
    }

    // 6. If already on Home and focus is inside main content -> Netflix behavior: Back moves focus to the Sidebar Menu!
    const active = document.activeElement as HTMLElement;
    // 7. Already in the menu on Home, or on a screen without the menu (profile
    // picker): leave the app (Android TV).
    if ((active && active.closest('aside')) || !document.querySelector('aside')) {
      window.dispatchEvent(new CustomEvent(EXIT_EVENT));
      return;
    }
    if (active && !active.closest('aside')) {
      const activeSidebarBtn =
        document.querySelector<HTMLElement>('aside nav button[data-active="true"]') ||
        document.querySelector<HTMLElement>('aside nav button');
      if (activeSidebarBtn) {
        applyTvFocus(activeSidebarBtn);
        setLastKeyPressed('MENU LATERAL');
      }
    }
  }, [
    isPlayerOpen,
    closePlayer,
    selectedVodModal,
    setSelectedVodModal,
    selectedSeriesModal,
    setSelectedSeriesModal,
    activeTab,
    setActiveTab,
    applyTvFocus,
  ]);

  // Home Button Action
  const triggerHome = useCallback(() => {
    setLastKeyPressed('HOME (INÍCIO)');
    if (isPlayerOpen) closePlayer();
    if (selectedVodModal) setSelectedVodModal(null);
    if (selectedSeriesModal) setSelectedSeriesModal(null);
    setActiveTab('home');
    setTimeout(() => {
      const firstCard = document.querySelector<HTMLElement>('main .tv-card');
      if (firstCard) applyTvFocus(firstCard);
    }, 150);
  }, [
    isPlayerOpen,
    closePlayer,
    selectedVodModal,
    setSelectedVodModal,
    selectedSeriesModal,
    setSelectedSeriesModal,
    setActiveTab,
    applyTvFocus,
  ]);

  // Media Controls
  const triggerPlayPause = useCallback(() => {
    setLastKeyPressed('PLAY / PAUSA');
    window.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }));
  }, []);

  const triggerRewind = useCallback(() => {
    setLastKeyPressed('RETROCEDER (-10s)');
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft' }));
  }, []);

  const triggerFastForward = useCallback(() => {
    setLastKeyPressed('AVANÇAR (+10s)');
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight' }));
  }, []);

  // Channel Step (Next / Previous)
  const triggerChannelStep = useCallback(
    (offset: 1 | -1) => {
      if (filteredChannels.length === 0) return;
      setLastKeyPressed(offset === 1 ? 'CANAL +' : 'CANAL -');

      const currentIndex = currentStream?.channel
        ? filteredChannels.findIndex((c) => c.id === currentStream.channel?.id)
        : 0;

      const nextIndex = (currentIndex + offset + filteredChannels.length) % filteredChannels.length;
      const nextChannel = filteredChannels[nextIndex];
      if (nextChannel) {
        playChannel(nextChannel);
      }
    },
    [filteredChannels, currentStream, playChannel]
  );

  // Volume Adjustment
  const triggerVolume = useCallback((action: 'up' | 'down' | 'mute') => {
    setLastKeyPressed(action === 'mute' ? 'MUDO' : action === 'up' ? 'VOL +' : 'VOL -');
    if (action === 'mute') {
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'm' }));
    } else {
      const video = document.querySelector('video');
      if (video) {
        video.volume = Math.min(1, Math.max(0, video.volume + (action === 'up' ? 0.1 : -0.1)));
      }
    }
  }, []);

  // Simulated Voice Search
  const triggerVoiceSearch = useCallback(() => {
    const samples = ['NASA', 'Esportes', 'Notícias', 'Filmes 4K', 'Documentários'];
    const chosen = samples[Math.floor(Math.random() * samples.length)];
    setLastKeyPressed(`VOZ: "${chosen}"`);

    const searchInput = document.querySelector<HTMLInputElement>('header input[type="text"]');
    if (searchInput) {
      searchInput.value = chosen;
      searchInput.dispatchEvent(new Event('input', { bubbles: true }));
      setActiveTab('search');
    }
  }, [setActiveTab]);

  // On a real TV the physical remote is used: the on-screen simulator is only for desktop testing.
  const hideSimulator = isNativeApp() || deviceProfile.isAndroidTv;

  // Focus can also arrive without the remote handler (autoFocus, touch, a
  // modal opening): mirror it so the focus ring is always visible on TV.
  useEffect(() => {
    if (!tvMode) return;
    const onFocusIn = (e: FocusEvent) => {
      const el = e.target as HTMLElement | null;
      if (!el || el === document.body || el.classList.contains('tv-focused')) return;
      document.querySelectorAll('.tv-focused').forEach((prev) => prev.classList.remove('tv-focused'));
      el.classList.add('tv-focused');
    };
    document.addEventListener('focusin', onFocusIn);
    return () => document.removeEventListener('focusin', onFocusIn);
  }, [tvMode]);

  // A remote has no pointer: whenever nothing is focused (app start, new screen,
  // a focused button that disappeared, closed modal), put focus on the first
  // thing the user can act on. A light watchdog covers every case.
  useEffect(() => {
    if (!tvMode || isPlayerOpen) return;
    const ensureFocus = () => {
      const active = document.activeElement as HTMLElement | null;
      if (active && active !== document.body && document.body.contains(active)) return;
      const modal = document.querySelector<HTMLElement>('.fixed.inset-0.z-50');
      const target = modal
        ? modal.querySelector<HTMLElement>('[data-autofocus]') || modal.querySelector<HTMLElement>('[autofocus], .tv-card, button')
        : document.querySelector<HTMLElement>('main [data-autofocus]') ||
          // Content first (cards are not <button>s), then any control.
          document.querySelector<HTMLElement>('main .tv-card:not(button)') ||
          document.querySelector<HTMLElement>('main .tv-card, main button') ||
          // Screens without the main layout (profile picker)
          document.querySelector<HTMLElement>('[data-autofocus], .tv-card');
      if (target) applyTvFocus(target);
    };
    const first = setTimeout(ensureFocus, 300);
    const timer = setInterval(ensureFocus, 700);
    return () => {
      clearTimeout(first);
      clearInterval(timer);
    };
  }, [tvMode, isPlayerOpen, applyTvFocus]);

  // Keyboard Event Listener for Firestick / Android TV remote keys
  const lastKeyTimeRef = useRef<number>(0);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Text fields keep Left/Right (caret) and typing; Up/Down leave the field
      // so a remote can never get stuck inside the search box.
      const target = e.target as HTMLElement | null;
      const isField =
        !!target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT' || target.isContentEditable);
      if (isField) {
        if (e.key === 'Escape') {
          e.preventDefault();
          target!.blur();
          return;
        }
        const isTextInput = target!.tagName === 'TEXTAREA' || (target!.tagName === 'INPUT' && !['checkbox', 'radio', 'range', 'file', 'button', 'submit'].includes((target as HTMLInputElement).type));
        if (!(e.key === 'ArrowUp' || e.key === 'ArrowDown') || target!.tagName === 'SELECT' || (target!.tagName === 'TEXTAREA' && isTextInput)) {
          return;
        }
      }

      // 45ms Debounce for 60fps smooth scrolling during D-pad long-press
      const now = performance.now();
      if (now - lastKeyTimeRef.current < 45) {
        return;
      }
      lastKeyTimeRef.current = now;

      if (e.key === 'ArrowUp') {
        e.preventDefault();
        setLastKeyPressed('D-PAD CIMA');
        navigateDirectional('up');
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        setLastKeyPressed('D-PAD BAIXO');
        navigateDirectional('down');
      } else if (e.key === 'ArrowLeft') {
        const isDrawerOrControlsFocused = !!document.activeElement?.closest('.quick-drawer, header, footer');
        if (!isPlayerOpen || isDrawerOrControlsFocused) {
          e.preventDefault();
          setLastKeyPressed('D-PAD ESQUERDA');
          navigateDirectional('left');
        }
      } else if (e.key === 'ArrowRight') {
        const isDrawerOrControlsFocused = !!document.activeElement?.closest('.quick-drawer, header, footer');
        if (!isPlayerOpen || isDrawerOrControlsFocused) {
          e.preventDefault();
          setLastKeyPressed('D-PAD DIREITA');
          navigateDirectional('right');
        }
      } else if (e.key === 'Enter') {
        // The focused card already handled Enter itself (and prevented default).
        if (e.defaultPrevented) return;
        e.preventDefault();
        triggerSelect();
      } else if (e.key === 'Escape' || e.key === 'Backspace') {
        e.preventDefault();
        triggerBack();
      } else if (e.key === 'PageUp') {
        e.preventDefault();
        triggerChannelStep(1);
      } else if (e.key === 'PageDown') {
        e.preventDefault();
        triggerChannelStep(-1);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigateDirectional, triggerSelect, triggerBack, triggerChannelStep, isPlayerOpen]);

  // Automated Firestick Simulation Tour (End-to-End Demo)
  const runAutoPilotTour = () => {
    if (isAutoTourRunning) return;
    setIsAutoTourRunning(true);
    autoTourTimeouts.current.forEach((t) => clearTimeout(t));
    autoTourTimeouts.current = [];

    const plan = [
      // 1. Return home and focus first channel
      { delay: 100, action: () => triggerHome() },
      // 2. Move right to next channel
      {
        delay: 1000,
        action: () => {
          setLastKeyPressed('AUTO: D-PAD DIREITA');
          navigateDirectional('right');
        },
      },
      // 3. Move right to third channel
      {
        delay: 2000,
        action: () => {
          setLastKeyPressed('AUTO: D-PAD DIREITA');
          navigateDirectional('right');
        },
      },
      // 4. Press OK to launch Player
      {
        delay: 3000,
        action: () => {
          setLastKeyPressed('AUTO: PRESSIONAR OK');
          triggerSelect();
        },
      },
      // 5. Test volume up in player
      {
        delay: 4500,
        action: () => {
          setLastKeyPressed('AUTO: AUMENTAR VOLUME');
          triggerVolume('up');
        },
      },
      // 6. Test pause
      {
        delay: 5800,
        action: () => {
          setLastKeyPressed('AUTO: PLAY/PAUSA');
          triggerPlayPause();
        },
      },
      // 7. Test unpause
      {
        delay: 6800,
        action: () => {
          setLastKeyPressed('AUTO: REPRODUZIR');
          triggerPlayPause();
        },
      },
      // 8. Press Back button to return to Home
      {
        delay: 7800,
        action: () => {
          setLastKeyPressed('AUTO: BOTÃO VOLTAR (BACK)');
          triggerBack();
        },
      },
      // 9. Navigate down to movies
      {
        delay: 9000,
        action: () => {
          setActiveTab('vod');
          setTimeout(() => {
            const firstVod = document.querySelector<HTMLElement>('.tv-card');
            if (firstVod) applyTvFocus(firstVod);
          }, 150);
        },
      },
      // 10. Open first movie modal
      {
        delay: 10500,
        action: () => {
          setLastKeyPressed('AUTO: ABRIR DETALHES DO FILME');
          triggerSelect();
        },
      },
      // 11. Close modal with Back button
      {
        delay: 12200,
        action: () => {
          setLastKeyPressed('AUTO: VOLTAR AO CATÁLOGO');
          triggerBack();
        },
      },
      // 12. Tour complete
      {
        delay: 13500,
        action: () => {
          setLastKeyPressed('SIMULAÇÃO CONCLUÍDA COM SUCESSO');
          setIsAutoTourRunning(false);
        },
      },
    ];

    plan.forEach(({ delay, action }) => {
      const t = setTimeout(action, delay);
      autoTourTimeouts.current.push(t);
    });
  };

  const stopAutoPilotTour = () => {
    autoTourTimeouts.current.forEach((t) => clearTimeout(t));
    autoTourTimeouts.current = [];
    setIsAutoTourRunning(false);
    setLastKeyPressed('Simulação Interrompida');
  };

  if (hideSimulator) return null;

  return (
    <>
      {/* Floating Remote Trigger Button (Discreet, Clean, No Debug HUD) */}
      {!isRemoteVisible && (
        <button
          onClick={() => setIsRemoteVisible(true)}
          className="fixed bottom-5 right-5 z-40 w-11 h-11 rounded-2xl bg-[#141418]/80 hover:bg-[#7C5CFF] text-[#A1A1AA] hover:text-white border border-[#2A2A31] hover:border-[#7C5CFF] shadow-xl backdrop-blur-md flex items-center justify-center transition-all opacity-40 hover:opacity-100 cursor-pointer"
          title="Abrir Simulador de Controle Remoto Firestick"
        >
          <Tv className="w-5 h-5" />
        </button>
      )}

      {/* Realistic Amazon Fire TV Stick Remote Widget */}
      {isRemoteVisible && (
        <div className="fixed bottom-6 right-6 z-50 w-72 bg-[#121216] border-2 border-[#2A2A31] rounded-[42px] p-5 shadow-2xl select-none animate-in slide-in-from-bottom duration-200 text-white font-sans flex flex-col items-center">
          {/* Remote Top Bar */}
          <div className="w-full flex items-center justify-between pb-3 border-b border-[#2A2A31]/80">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-[#22D3A6]" />
              <span className="text-[11px] font-bold text-white tracking-wider font-['Outfit']">
                AMAZON FIRE TV
              </span>
            </div>
            <button
              onClick={() => setIsRemoteVisible(false)}
              className="w-6 h-6 rounded-full hover:bg-[#2A2A31] text-[#A1A1AA] hover:text-white flex items-center justify-center cursor-pointer transition-colors"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Voice / Mic Button */}
          <div className="my-3 flex justify-center">
            <button
              onClick={triggerVoiceSearch}
              className="w-10 h-10 rounded-full bg-[#1E1E24] hover:bg-[#2A2A31] text-[#22D3A6] flex items-center justify-center transition-transform active:scale-90 cursor-pointer border border-[#2A2A31] shadow"
              title="Busca por Voz (Alexa)"
            >
              <Mic className="w-4 h-4" />
            </button>
          </div>

          {/* D-PAD Navigational Ring (Netflix / Firestick Style) */}
          <div className="relative w-44 h-44 rounded-full bg-[#17171C] border border-[#2A2A31] flex items-center justify-center p-2 shadow-inner my-2">
            {/* Up Button */}
            <button
              onClick={() => {
                setLastKeyPressed('D-PAD CIMA');
                navigateDirectional('up');
              }}
              className="absolute top-1.5 left-1/2 -translate-x-1/2 w-16 h-10 rounded-t-full hover:bg-[#7C5CFF]/40 flex items-center justify-center text-[#A1A1AA] hover:text-white cursor-pointer active:scale-95 transition-all"
              title="Para Cima (Arrow Up)"
            >
              <ChevronUp className="w-6 h-6" />
            </button>

            {/* Down Button */}
            <button
              onClick={() => {
                setLastKeyPressed('D-PAD BAIXO');
                navigateDirectional('down');
              }}
              className="absolute bottom-1.5 left-1/2 -translate-x-1/2 w-16 h-10 rounded-b-full hover:bg-[#7C5CFF]/40 flex items-center justify-center text-[#A1A1AA] hover:text-white cursor-pointer active:scale-95 transition-all"
              title="Para Baixo (Arrow Down)"
            >
              <ChevronDown className="w-6 h-6" />
            </button>

            {/* Left Button */}
            <button
              onClick={() => {
                setLastKeyPressed('D-PAD ESQUERDA');
                navigateDirectional('left');
              }}
              className="absolute left-1.5 top-1/2 -translate-y-1/2 w-10 h-16 rounded-l-full hover:bg-[#7C5CFF]/40 flex items-center justify-center text-[#A1A1AA] hover:text-white cursor-pointer active:scale-95 transition-all"
              title="Para Esquerda (Arrow Left)"
            >
              <ChevronLeft className="w-6 h-6" />
            </button>

            {/* Right Button */}
            <button
              onClick={() => {
                setLastKeyPressed('D-PAD DIREITA');
                navigateDirectional('right');
              }}
              className="absolute right-1.5 top-1/2 -translate-y-1/2 w-10 h-16 rounded-r-full hover:bg-[#7C5CFF]/40 flex items-center justify-center text-[#A1A1AA] hover:text-white cursor-pointer active:scale-95 transition-all"
              title="Para Direita (Arrow Right)"
            >
              <ChevronRight className="w-6 h-6" />
            </button>

            {/* Center SELECT / OK Button */}
            <button
              onClick={triggerSelect}
              className="w-16 h-16 rounded-full bg-gradient-to-tr from-[#7C5CFF] to-[#2B1F66] hover:scale-105 active:scale-95 flex items-center justify-center text-white font-bold text-xs shadow-lg shadow-[#7C5CFF]/50 border border-white/20 cursor-pointer transition-transform"
              title="Selecionar / Confirmar (Enter)"
            >
              OK
            </button>
          </div>

          {/* Navigation Controls: Back, Home, Menu */}
          <div className="grid grid-cols-3 gap-3 w-full my-3 px-2">
            <button
              onClick={triggerBack}
              className="py-2.5 rounded-xl bg-[#1E1E24] hover:bg-[#2A2A31] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-all active:scale-90 cursor-pointer"
              title="Voltar (Esc / Backspace)"
            >
              <CornerUpLeft className="w-4 h-4" />
            </button>
            <button
              onClick={triggerHome}
              className="py-2.5 rounded-xl bg-[#1E1E24] hover:bg-[#2A2A31] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-all active:scale-90 cursor-pointer"
              title="Início (Home)"
            >
              <Home className="w-4 h-4" />
            </button>
            <button
              onClick={() => {
                setLastKeyPressed('MENU');
                // If in player, opens channel drawer, otherwise opens sidebar
                window.dispatchEvent(new KeyboardEvent('keydown', { key: 'm' }));
              }}
              className="py-2.5 rounded-xl bg-[#1E1E24] hover:bg-[#2A2A31] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-all active:scale-90 cursor-pointer"
              title="Menu / Gaveta"
            >
              <Menu className="w-4 h-4" />
            </button>
          </div>

          {/* Media Playback Controls: Rewind, Play/Pause, Fast Forward */}
          <div className="grid grid-cols-3 gap-3 w-full my-1 px-2">
            <button
              onClick={triggerRewind}
              className="py-2.5 rounded-xl bg-[#1E1E24] hover:bg-[#2A2A31] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-all active:scale-90 cursor-pointer"
              title="Retroceder 10s"
            >
              <Rewind className="w-4 h-4" />
            </button>
            <button
              onClick={triggerPlayPause}
              className="py-2.5 rounded-xl bg-[#22D3A6]/20 hover:bg-[#22D3A6]/30 text-[#22D3A6] flex items-center justify-center transition-all active:scale-90 cursor-pointer border border-[#22D3A6]/40"
              title="Play / Pause"
            >
              <Play className="w-4 h-4 fill-current ml-0.5" />
            </button>
            <button
              onClick={triggerFastForward}
              className="py-2.5 rounded-xl bg-[#1E1E24] hover:bg-[#2A2A31] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-all active:scale-90 cursor-pointer"
              title="Avançar 10s"
            >
              <FastForward className="w-4 h-4" />
            </button>
          </div>

          {/* Volume and Channel Switchers */}
          <div className="grid grid-cols-2 gap-3 w-full my-3 px-2">
            {/* Volume Rocker */}
            <div className="flex items-center justify-between p-1 rounded-xl bg-[#17171C] border border-[#2A2A31]">
              <button
                onClick={() => triggerVolume('down')}
                className="w-7 h-7 rounded-lg hover:bg-[#2A2A31] flex items-center justify-center text-xs text-[#A1A1AA] hover:text-white cursor-pointer font-bold"
                title="Diminuir Volume"
              >
                -
              </button>
              <span className="text-[10px] font-bold text-[#A1A1AA] uppercase">Vol</span>
              <button
                onClick={() => triggerVolume('up')}
                className="w-7 h-7 rounded-lg hover:bg-[#2A2A31] flex items-center justify-center text-xs text-[#A1A1AA] hover:text-white cursor-pointer font-bold"
                title="Aumentar Volume"
              >
                +
              </button>
            </div>

            {/* Channel Rocker */}
            <div className="flex items-center justify-between p-1 rounded-xl bg-[#17171C] border border-[#2A2A31]">
              <button
                onClick={() => triggerChannelStep(-1)}
                className="w-7 h-7 rounded-lg hover:bg-[#2A2A31] flex items-center justify-center text-xs text-[#A1A1AA] hover:text-white cursor-pointer font-bold"
                title="Canal Anterior"
              >
                ▼
              </button>
              <span className="text-[10px] font-bold text-[#22D3A6] uppercase">CH</span>
              <button
                onClick={() => triggerChannelStep(1)}
                className="w-7 h-7 rounded-lg hover:bg-[#2A2A31] flex items-center justify-center text-xs text-[#A1A1AA] hover:text-white cursor-pointer font-bold"
                title="Próximo Canal"
              >
                ▲
              </button>
            </div>
          </div>

          {/* Automated Tour Simulation Trigger */}
          <div className="w-full pt-2 border-t border-[#2A2A31]/80">
            {isAutoTourRunning ? (
              <button
                onClick={stopAutoPilotTour}
                className="w-full py-2.5 rounded-xl bg-[#FF5468] text-white font-bold text-xs flex items-center justify-center gap-2 cursor-pointer shadow-lg animate-pulse"
              >
                <X className="w-4 h-4" />
                Interromper Simulação
              </button>
            ) : (
              <button
                onClick={runAutoPilotTour}
                className="w-full py-2.5 rounded-xl bg-gradient-to-r from-[#7C5CFF] to-[#22D3A6] hover:opacity-90 text-white font-bold text-xs flex items-center justify-center gap-2 cursor-pointer shadow-lg shadow-[#7C5CFF]/30 transition-transform active:scale-95"
              >
                <Zap className="w-4 h-4 fill-current" />
                Simulação Automática Firestick
              </button>
            )}
          </div>
        </div>
      )}
    </>
  );
};
