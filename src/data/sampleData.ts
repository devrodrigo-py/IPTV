import { Channel, EpgProgram, Playlist, UserProfile, VodItem, SeriesItem, AppSettings, WatchStats } from '../types';

export const DEFAULT_PROFILES: UserProfile[] = [
  {
    id: 'prof_master',
    name: 'Rodrigo (Principal)',
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    isKids: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prof_livingroom',
    name: 'Sala de Estar',
    avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
    isKids: false,
    createdAt: new Date().toISOString(),
  },
  {
    id: 'prof_kids',
    name: 'Espaço Kids',
    avatar: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150&auto=format&fit=crop&q=80',
    isKids: true,
    pin: '1234',
    createdAt: new Date().toISOString(),
  },
];

export const DEFAULT_SETTINGS: AppSettings = {
  themeAccent: 'violet',
  bufferMode: 'balanced',
  tvMode: false,
  parentalControlEnabled: true,
  masterPin: '0000',
  streamAutoplay: true,
};

export const INITIAL_PLAYLISTS: Playlist[] = [
  {
    id: 'pl_default',
    name: 'Nebula Global Discovery',
    type: 'm3u',
    url: 'https://iptv-org.github.io/iptv/index.m3u',
    channelCount: 12,
    lastSync: new Date().toISOString(),
    isActive: true,
    autoSyncMinutes: 1440,
  },
  {
    id: 'pl_demo_xtream',
    name: 'Servidor Demonstração Xtream',
    type: 'xtream',
    url: 'http://demo.iptv-server.net:8080',
    username: 'nebula_user',
    password: '••••••••',
    channelCount: 8,
    lastSync: new Date(Date.now() - 3600000 * 2).toISOString(),
    isActive: true,
  },
];

export const INITIAL_CHANNELS: Channel[] = [
  {
    id: 'ch_1',
    playlistId: 'pl_default',
    name: 'NASA TV HD (Ciência & Espaço)',
    streamUrl: 'https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/e5/NASA_logo.svg',
    groupTitle: 'Documentários',
    tvgId: 'nasa.tv',
    resolution: 'FHD',
    isFavorite: true,
  },
  {
    id: 'ch_2',
    playlistId: 'pl_default',
    name: 'Bloomberg Television',
    streamUrl: 'https://liveproduseast.akamaized.net/us/Channel-HD-AWS-virginia-1/fastly.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/5e/Bloomberg_Television_logo.svg',
    groupTitle: 'Notícias',
    tvgId: 'bloomberg.us',
    resolution: 'HD',
    isFavorite: true,
  },
  {
    id: 'ch_3',
    playlistId: 'pl_default',
    name: 'Euronews English Live',
    streamUrl: 'https://euronews-euronews-world-1-au.samsung.wurl.tv/playlist.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/47/Euronews_logo_2016.svg',
    groupTitle: 'Notícias',
    tvgId: 'euronews.en',
    resolution: 'HD',
    isFavorite: false,
  },
  {
    id: 'ch_4',
    playlistId: 'pl_default',
    name: 'Red Bull TV Extreme Sports',
    streamUrl: 'https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f5/Red_Bull_TV_logo.svg/512px-Red_Bull_TV_logo.svg.png',
    groupTitle: 'Esportes',
    tvgId: 'redbull.tv',
    resolution: 'FHD',
    isFavorite: true,
  },
  {
    id: 'ch_5',
    playlistId: 'pl_default',
    name: 'DW English World News',
    streamUrl: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/7/75/Deutsche_Welle_Logo.svg',
    groupTitle: 'Notícias',
    tvgId: 'dw.en',
    resolution: 'HD',
    isFavorite: false,
  },
  {
    id: 'ch_6',
    playlistId: 'pl_default',
    name: 'France 24 English Direct',
    streamUrl: 'https://stream.france24.com/hls/live/2037593/F24_EN_LO_HLS/master.m3u8',
    logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/ec/France_24_logo.svg',
    groupTitle: 'Notícias',
    tvgId: 'france24.en',
    resolution: 'HD',
    isFavorite: false,
  },
  {
    id: 'ch_7',
    playlistId: 'pl_default',
    name: 'Retro Toons & Cartoons Classic',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Infantil',
    tvgId: 'retrotoons.tv',
    resolution: 'HD',
    isFavorite: true,
  },
  {
    id: 'ch_8',
    playlistId: 'pl_default',
    name: 'CineMax Nebula 4K Showcase',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Filmes & Séries',
    tvgId: 'cinemax.nebula',
    resolution: '4K',
    isFavorite: true,
  },
  {
    id: 'ch_9',
    playlistId: 'pl_default',
    name: 'Wild Planet 4K Documentary',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Documentários',
    tvgId: 'wildplanet.doc',
    resolution: '4K',
    isFavorite: false,
  },
  {
    id: 'ch_10',
    playlistId: 'pl_default',
    name: 'Ultra Beats Club & Música',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Música',
    tvgId: 'ultrabeats.music',
    resolution: 'FHD',
    isFavorite: false,
  },
  {
    id: 'ch_11',
    playlistId: 'pl_default',
    name: 'Sua TV Ao Vivo (Local Brasil)',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Variedades',
    tvgId: 'suatv.br',
    resolution: 'HD',
    isFavorite: false,
  },
  {
    id: 'ch_12',
    playlistId: 'pl_default',
    name: 'Motorsport & Turbo TV',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackSeeTheWorld.mp4',
    logoUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=100&auto=format&fit=crop&q=80',
    groupTitle: 'Esportes',
    tvgId: 'turbo.sports',
    resolution: 'FHD',
    isFavorite: false,
  },
];

// Helper to generate dynamic EPG programs around current time
export function generateSampleEpg(): EpgProgram[] {
  const now = new Date();
  const currentHour = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), 0, 0);

  const programs: EpgProgram[] = [];

  const scheduleTemplates: Record<string, Array<{ title: string; category: string; desc: string; durMin: number }>> = {
    'ch_1': [
      { title: 'ISS Live Views from Orbit', category: 'Documentário', desc: 'Imagens em ultra-alta definição e telemetria da Estação Espacial Internacional.', durMin: 60 },
      { title: 'Artemis Moon Mission Update', category: 'Ciência', desc: 'Últimas notícias sobre a nova geração de foguetes SLS e cápsula Orion.', durMin: 60 },
      { title: 'James Webb Telescope Discoveries', category: 'Astronomia', desc: 'Análise de galáxias primordiais e exoplanetas na zona habitável.', durMin: 60 },
      { title: 'Deep Space Frontiers', category: 'Documentário', desc: 'Sondas Voyager e a exploração do espaço interestelar.', durMin: 60 },
    ],
    'ch_2': [
      { title: 'Bloomberg Surveillance Americas', category: 'Economia', desc: 'Abertura dos mercados em Wall Street, inflação e taxas de juros.', durMin: 60 },
      { title: 'Balance of Power with Joe Mathieu', category: 'Notícias', desc: 'Política global, diplomacia e impactos no comércio mundial.', durMin: 60 },
      { title: 'Technology & AI Breakthroughs', category: 'Tecnologia', desc: 'Startups de ponta, computação quântica e semicondutores.', durMin: 60 },
      { title: 'Global Commodities & Energy', category: 'Finanças', desc: 'Preço do barril de petróleo, transição verde e minerais raros.', durMin: 60 },
    ],
    'ch_4': [
      { title: 'Red Bull Cliff Diving World Series', category: 'Esportes', desc: 'Saltos de penhascos impressionantes nas águas de Polignano a Mare.', durMin: 60 },
      { title: 'F1 Trackside Insights & Aerodynamics', category: 'Automobilismo', desc: 'Bastidores dos monopostos mais rápidos do planeta.', durMin: 60 },
      { title: 'Crankworx Downhill Mountain Bike', category: 'Radicais', desc: 'Descidas vertiginosas em Whistler com os melhores pilotos do mundo.', durMin: 60 },
      { title: 'Freeride World Tour Verbier', category: 'Esportes de Inverno', desc: 'Snowboard e esqui alpino extremo nos Alpes Suíços.', durMin: 60 },
    ],
    'ch_8': [
      { title: 'Blade Runner 2049 (Nebula 4K HDR)', category: 'Ficção Científica', desc: 'Um jovem blade runner descobre um segredo sepultado há muito tempo.', durMin: 120 },
      { title: 'Interstellar Odyssey 4K', category: 'Ficção Científica', desc: 'Uma equipe de exploradores viaja através de um buraco de minhoca no espaço.', durMin: 120 },
    ],
    'ch_7': [
      { title: 'O Coelho Cósmico & Aventuras', category: 'Infantil', desc: 'Aventuras na floresta encantada com muita animação clássica.', durMin: 30 },
      { title: 'A Turma dos Brinquedos Voadores', category: 'Infantil', desc: 'Desenhos coloridos e educativos para toda a família.', durMin: 30 },
      { title: 'Fábulas Animadas do Milênio', category: 'Infantil', desc: 'Histórias divertidas sobre amizade e cooperação.', durMin: 30 },
      { title: 'Planeta Cartoon Divertido', category: 'Infantil', desc: 'Maratona com os personagens mais alegres da telinha.', durMin: 30 },
    ],
  };

  INITIAL_CHANNELS.forEach((ch) => {
    const list = scheduleTemplates[ch.id] || [
      { title: `Transmissão Ao Vivo: ${ch.name}`, category: ch.groupTitle || 'Geral', desc: 'Programação continuada com os melhores conteúdos ao vivo.', durMin: 60 },
      { title: `Edição Especial da Tarde`, category: ch.groupTitle || 'Geral', desc: 'Destaques e reportagens exclusivas para assinantes Nebula.', durMin: 60 },
      { title: `Nebula Prime Show`, category: ch.groupTitle || 'Geral', desc: 'O programa mais premiado da grade internacional.', durMin: 60 },
      { title: `Encerramento & Madrugada`, category: ch.groupTitle || 'Geral', desc: 'Música ambiente e resumos dos acontecimentos.', durMin: 60 },
    ];

    let t = new Date(currentHour.getTime() - 3600000); // start 1 hour before current
    list.forEach((prog, pIdx) => {
      const startUtc = new Date(t);
      const endUtc = new Date(t.getTime() + prog.durMin * 60000);
      t = endUtc;

      programs.push({
        id: `epg_${ch.id}_${pIdx}`,
        channelId: ch.id,
        title: prog.title,
        category: prog.category,
        description: prog.desc,
        startUtc: startUtc.toISOString(),
        endUtc: endUtc.toISOString(),
      });
    });
  });

  return programs;
}

export const INITIAL_VOD: VodItem[] = [
  {
    id: 'vod_1',
    title: 'Tears of Steel: A Resistência Cyber',
    posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=1200&auto=format&fit=crop&q=80',
    description: 'Em um futuro distópico onde a tecnologia biomecânica quase destruiu a humanidade, um grupo de cientistas no antigo observatório de Amsterdã tenta reescrever o destino através de uma memória compartilhada.',
    year: 2024,
    rating: 8.8,
    durationMinutes: 124,
    category: 'Ficção Científica',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    director: 'Ian Hubert',
    cast: ['Derek de Lint', 'Sergio Hasselbaink', 'Rogier Schippers'],
  },
  {
    id: 'vod_2',
    title: 'Sintel: O Legado do Dragão Solitário',
    posterUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1200&auto=format&fit=crop&q=80',
    description: 'Uma jovem guerreira viaja através de terras ermas e montanhas geladas em busca de seu companheiro dragão filhote, que foi capturado por predadores celestiais.',
    year: 2023,
    rating: 9.1,
    durationMinutes: 98,
    category: 'Fantasia',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    director: 'Colin Levy',
    cast: ['Halina Reijn', 'Thom Hoffman'],
  },
  {
    id: 'vod_3',
    title: 'Big Buck Bunny: O Guardião da Floresta',
    posterUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
    description: 'Quando uma trupe de animais encrenqueiros ameaça a paz da clareira e agride borboletas indefesas, o gigante e bondoso coelho decide dar uma lição inesquecível a todos.',
    year: 2024,
    rating: 8.5,
    durationMinutes: 86,
    category: 'Animação',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    director: 'Sacha Goedegebure',
    cast: ['Vozes Originais Studio Blender'],
  },
  {
    id: 'vod_4',
    title: 'Elephant\'s Dream: Máquinas do Inconsciente',
    posterUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
    description: 'Dois homens exploram uma estrutura mecânica surreal e labiríntica cujos motores refletem seus próprios medos, ilusões e ambições mais obscuras.',
    year: 2023,
    rating: 8.2,
    durationMinutes: 110,
    category: 'Mistério',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    director: 'Bassam Kurdali',
    cast: ['Tygo Gernandt', 'Cas Jansen'],
  },
  {
    id: 'vod_5',
    title: 'Cosmic Horizons: A Velocidade da Luz',
    posterUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=1200&auto=format&fit=crop&q=80',
    description: 'Uma expedição astronômica que investiga os confins do universo observável, analisando ondas gravitacionais e supernovas colossais.',
    year: 2025,
    rating: 9.4,
    durationMinutes: 135,
    category: 'Documentário',
    streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    director: 'Marcus Thorne',
    cast: ['Dra. Elena Rostov', 'Prof. Neil Armstrong Jr.'],
  },
];

export const INITIAL_SERIES: SeriesItem[] = [
  {
    id: 'ser_1',
    title: 'Nebula Protocol: Sombras da Rede',
    posterUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&auto=format&fit=crop&q=80',
    overview: 'Uma rede descentralizada de hackers descobre uma transmissão criptografada enviada do fundo do oceano Pacífico que ameaça derrubar toda a infraestrutura de telecomunicações do planeta.',
    rating: 9.2,
    category: 'Suspense Tecnológico',
    seasons: [
      {
        seasonNumber: 1,
        title: 'Temporada 1: O Sinal Fantasma',
        episodes: [
          {
            id: 'ep_1_1',
            episodeNumber: 1,
            title: 'Pacote 0x01: Conexão Perdida',
            overview: 'Uma queda maciça nos cabos submarinos do Atlântico leva a analista Clara a uma frequência desconhecida.',
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
            durationMinutes: 48,
            stillUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400&auto=format&fit=crop&q=80',
          },
          {
            id: 'ep_1_2',
            episodeNumber: 2,
            title: 'Pacote 0x02: Chave Assimétrica',
            overview: 'A decodificação do cabeçalho revela coordenadas que apontam para uma base militar abandonada nos Açores.',
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
            durationMinutes: 52,
            stillUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400&auto=format&fit=crop&q=80',
          },
          {
            id: 'ep_1_3',
            episodeNumber: 3,
            title: 'Pacote 0x03: Eco no Abismo',
            overview: 'Confrontados por agentes de segurança privada, a equipe precisa transferir os dados antes do blackout total.',
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            durationMinutes: 55,
            stillUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&auto=format&fit=crop&q=80',
          },
        ],
      },
      {
        seasonNumber: 2,
        title: 'Temporada 2: O Firewall Global',
        episodes: [
          {
            id: 'ep_2_1',
            episodeNumber: 1,
            title: 'Reinicialização Forçada',
            overview: 'Seis meses após o incidente, uma nova IA assume o controle dos servidores do governo.',
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
            durationMinutes: 50,
            stillUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=400&auto=format&fit=crop&q=80',
          },
        ],
      },
    ],
  },
  {
    id: 'ser_2',
    title: 'Aurora: Guardiões da Antártica',
    posterUrl: 'https://images.unsplash.com/photo-1483086431886-3590a88317f6?w=400&auto=format&fit=crop&q=80',
    backdropUrl: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?w=1200&auto=format&fit=crop&q=80',
    overview: 'Cientistas isolados durante a longa noite polar encontram uma cápsula congelada a três quilômetros de profundidade no gelo da Antártica.',
    rating: 8.9,
    category: 'Drama & Mistério',
    seasons: [
      {
        seasonNumber: 1,
        title: 'Temporada 1: O Núcleo de Gelo',
        episodes: [
          {
            id: 'ep_aurora_1',
            episodeNumber: 1,
            title: 'Noite Sem Fim',
            overview: 'A base perde contato com a estação costeira enquanto a tempestade atinge níveis recordes.',
            streamUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
            durationMinutes: 46,
            stillUrl: 'https://images.unsplash.com/photo-1483086431886-3590a88317f6?w=400&auto=format&fit=crop&q=80',
          },
        ],
      },
    ],
  },
];

export const INITIAL_STATS: WatchStats = {
  totalMinutesWatched: 1420, // ~23.6 hours
  channelPlayCounts: {
    'ch_1': 42,
    'ch_4': 38,
    'ch_2': 29,
    'ch_8': 25,
    'ch_7': 14,
  },
  genreCounts: {
    'Documentários': 45,
    'Esportes': 38,
    'Notícias': 32,
    'Ficção Científica': 28,
    'Infantil': 14,
  },
  daysActive: 19,
  lastWatchedDate: new Date().toISOString(),
};
