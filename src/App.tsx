import React from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { Navbar } from './components/common/Navbar';
import { Sidebar } from './components/common/Sidebar';
import { MobileNav } from './components/common/MobileNav';
import { TvRemoteOverlay } from './components/common/TvRemoteOverlay';
import { VideoPlayer } from './components/player/VideoPlayer';
import { ProfileGate } from './components/profiles/ProfileGate';
import { NebulaWrappedModal } from './components/wrapped/NebulaWrappedModal';

import { HomeView } from './views/HomeView';
import { ChannelsView } from './views/ChannelsView';
import { VodView } from './views/VodView';
import { SeriesView } from './views/SeriesView';
import { FavoritesView } from './views/FavoritesView';
import { HistoryView } from './views/HistoryView';
import { PlaylistsView } from './views/PlaylistsView';
import { EpgView } from './views/EpgView';
import { MultiViewScreen } from './views/MultiViewScreen';
import { StatsView } from './views/StatsView';
import { SettingsView } from './views/SettingsView';
import { SearchView } from './views/SearchView';

const AppContent: React.FC = () => {
  const { activeProfile, isGateLocked, activeTab, isWrappedOpen, setIsWrappedOpen } = useApp();

  if (!activeProfile || isGateLocked) {
    return <ProfileGate />;
  }

  const renderActiveTab = () => {
    switch (activeTab) {
      case 'home':
        return <HomeView />;
      case 'channels':
        return <ChannelsView />;
      case 'vod':
        return <VodView />;
      case 'series':
        return <SeriesView />;
      case 'favorites':
        return <FavoritesView />;
      case 'history':
        return <HistoryView />;
      case 'playlists':
        return <PlaylistsView />;
      case 'epg':
        return <EpgView />;
      case 'multiview':
        return <MultiViewScreen />;
      case 'stats':
        return <StatsView />;
      case 'settings':
        return <SettingsView />;
      case 'search':
        return <SearchView />;
      default:
        return <HomeView />;
    }
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#07070F] text-[#F5F3FF]">
      {/* Desktop/Tablet Sidebar */}
      <div className="hidden md:block">
        <Sidebar />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-full min-w-0 overflow-hidden relative">
        <Navbar />

        <main className="flex-1 overflow-y-auto pb-20 md:pb-6">
          {renderActiveTab()}
        </main>

        {/* Mobile Navigation */}
        <MobileNav />
      </div>

      {/* Embedded / Fullscreen Video Player */}
      <VideoPlayer />

      {/* Nebula Wrapped 2026 Celebration Modal */}
      {isWrappedOpen && <NebulaWrappedModal onClose={() => setIsWrappedOpen(false)} />}

      {/* TV Mode Remote Overlay */}
      <TvRemoteOverlay />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AppProvider>
      <AppContent />
    </AppProvider>
  );
};

export default App;
