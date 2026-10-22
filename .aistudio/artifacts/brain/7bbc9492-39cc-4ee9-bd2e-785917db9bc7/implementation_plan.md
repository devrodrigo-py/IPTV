# Plano de Auditoria E2E e Correções de Produção — Nebula IPTV

Auditoria de ponta a ponta e plano de correção imediata nos 12 módulos do Nebula IPTV, eliminando fragilidades funcionais, bugs de concorrência, problemas de playback no Multiview, listeners globais invasivos e violações de UX.

---

## User Review & Critical Decisions

> [!IMPORTANT]
> **Decisões Confirmadas na Fase 1:**
> - **Escopo:** Auditoria completa e implacável em todos os 12 módulos (Home, Canais, Player, Multiview, EPG, VOD, Séries, Favoritos, Histórico, Playlists, Perfis/Parental e Ajustes/Backup).
> - **Estratégia de Resolução:** Relatório completo com indicação de arquivo e linha (`arquivo:linha`) seguido de implementação das correções de alta prioridade.

- **Multiview Player Engine**: Atualmente os tiles do Multiview utilizam `<video src="...">` nativo, que falha ao reproduzir streams `.m3u8` (HLS) no Chrome/Firefox. **Decisão:** Instanciar controladores Hls.js dedicados por tile com gerenciamento de lifecycle e liberação de memória.
- **Diálogos Nativos em iFrame**: `window.confirm` e `window.alert` causam travamento em iframes do sandbox. **Decisão:** Substituir todas as confirmações destrutivas por modais in-app fluidos com foco acessível.
- **Isolamento de Teclas Globais**: O player interceptava teclas como `Espaço`, `F` e `M` mesmo quando o usuário estava digitando em inputs de busca ou PIN. **Decisão:** Adicionar guardas de contexto `isInputFocused` em todos os listeners.

---

## 1. Overview & Core Concept

O **Nebula IPTV** é um hub de streaming moderno, projetado para alta performance tanto em navegadores desktop e mobile quanto em telas de TV (10-foot UI). 

A auditoria de produção tem como objetivo transformar o protótipo funcional em uma aplicação de nível de produção, garantindo:
1. Confiabilidade máxima na reprodução de transmissões HLS ao vivo em todos os modos (single player e multi-view grid).
2. Integridade e validação rigorosa na importação de listas M3U e arquivos XMLTV.
3. Proteção e resiliência em operações sensíveis (controle parental, exclusão de playlists e restauração de dados).
4. Experiência de usuário fluida, com zero telas vazias desprovidas de feedback (Empty States) e conformidade estética estrita com o Design System Nebula.

---

## 2. User Experience & Visual Design

### Visual Identity & Theme Tokens
A aplicação segue estritamente a paleta do Design System Nebula, com distribuição 60-30-10:
- **Canvas Neutro (60%)**: Void 950 (`#07070F`) para o background imersivo e Void 800 (`#16162A`) para superfícies de elevação única.
- **Superfícies Estruturais (30%)**: Void 600 (`#2A2A45`) para divisores e bordas ultrafinas de 1px.
- **Acentos Funcionais (10%)**:
  - `Nebula Violet` (`#6B4FE0`): Ações primárias, navegação ativa e botões CTA.
  - `Aurora Teal` (`#1FCFAE`): Indicador de sinal ao vivo, sucesso, áudio ativo e badges de resolução.
  - `Solar Coral` (`#FF6F91`): Favoritos, notas de avaliação e destaques comemorativos.

### Regras Anti-Slop & Disciplina Visual
- **Zero-Pill para Metadados**: Eliminação de cápsulas desnecessárias sobrepostas a posters; metadados (ano, duração, gênero) formatados com separadores tipográficos limpos (`·`).
- **Estados Vazios Acionáveis**: Todas as telas (Favoritos, Histórico, Busca, Canais e EPG) possuem ilustrações SVG minimalistas e um botão de ação primária (ex: "Explorar Grade", "Adicionar Playlist").
- **Proteção Visual em Mídia**: Scrims graduais com contraste $\ge 4.5:1$ em todos os overlays de vídeo e detalhes de VOD.
- **Acessibilidade TV & Teclado**: Anéis de foco luminosos com gradiente Violeta-Teal e suporte a `focus-visible`.

---

## 3. Diagnóstico de Auditoria por Módulo (`arquivo:linha`)

Abaixo estão os pontos críticos mapeados para correção imediata:

### 🔴 Bugs Críticos e Falhas Funcionais (Prioridade 1)
1. **Multiview sem suporte HLS nos tiles** (`src/views/MultiViewScreen.tsx:103`):
   - *Problema*: `<video src={channel.streamUrl}>` direto falha em navegadores desktop para transmissões HLS `.m3u8`.
   - *Correção*: Criar componente `MultiViewTile` que conecta instância de `Hls.js` individual quando suportado.
2. **Conflito de Teclas do Player durante Digitação** (`src/components/player/VideoPlayer.tsx:146`):
   - *Problema*: Pressionar `Espaço`, `M`, `F` ou setas enquanto digita na busca ou modal de PIN dispara atalhos de controle do vídeo em segundo plano.
   - *Correção*: Adicionar verificação `if (['INPUT', 'TEXTAREA'].includes((e.target as HTMLElement)?.tagName)) return;`.
3. **Uso de `window.confirm` bloqueável** (`src/views/SettingsView.tsx:56`):
   - *Problema*: `confirm()` bloqueia a thread e falha em iframes sandbox.
   - *Correção*: Criar modal de confirmação in-app elegante para limpeza de cache e remoção de playlists.

### 🟡 Fragilidades de Motor e Dados (Prioridade 2)
4. **Ausência de Confirmação na Exclusão de Playlist** (`src/views/PlaylistsView.tsx:139`):
   - *Problema*: Clique em "Excluir" remove instantaneamente a playlist e todos os canais associados sem confirmação prévia do usuário.
   - *Correção*: Conectar ao modal de confirmação de ação destrutiva.
5. **Falta de Sanitização e Validação no Import de JSON** (`src/data/storage.ts:186`):
   - *Problema*: Importa JSON sem validar schema, correndo risco de corromper o estado se campos estiverem ausentes.
   - *Correção*: Validador de integridade e fallback antes da gravação no `localStorage`.
6. **Fallback de Avatar Quebrado no Navbar** (`src/components/common/Navbar.tsx:76`):
   - *Problema*: `style.display = 'none'` esconde a imagem mas deixa um elemento vazio sem iniciais do perfil.
   - *Correção*: Renderizar badge com as iniciais do nome do perfil quando a imagem falhar.

### 🟢 Polimento de UI/UX e Acessibilidade (Prioridade 3)
7. **Pesquisa sem Reset ao Limpar** (`src/components/common/Navbar.tsx:34`):
   - *Problema*: Ao apagar todo o texto da busca, a tela permanece presa na aba `search`.
   - *Correção*: Retornar à aba anterior quando o input de busca for esvaziado.
8. **Navegação por Teclado no Nebula Wrapped** (`src/components/wrapped/NebulaWrappedModal.tsx:75`):
   - *Problema*: Usuário não consegue avançar slides pelas setas do teclado.
   - *Correção*: Adicionar listener para `ArrowLeft` / `ArrowRight`.

---

## 4. Technical Architecture & Component Hierarchy

```
┌────────────────────────────────────────────────────────────────────────┐
│                               App Shell                                │
│  ┌─────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │   Sidebar (Desktop)     │  │          Navbar & Search            │  │
│  │   - Brand Wordmark      │  │          - Global Search Input      │  │
│  │   - 11 Module Links     │  │          - TV Mode Toggle           │  │
│  │   - Wrapped Trigger     │  │          - Profile Switcher Dropdown│  │
│  └─────────────────────────┘  └─────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                       Main Viewport                              │  │
│  │  Home | Canais | VOD | Séries | Favoritos | Histórico |          │  │
│  │  Playlists | EPG | Multiview Grid | Estatísticas | Configurações │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │           Global Overlays & Player Architecture                  │  │
│  │  - VideoPlayer (HLS.js Engine + Quick Drawer + Quality Controls) │  │
│  │  - MultiViewTile (Independent Hls instances per tile)            │  │
│  │  - ProfileGate (PIN Gatekeeper + User Profiles)                  │  │
│  │  - ConfirmModal (Non-blocking in-app confirmation dialog)        │  │
│  │  - TvRemoteOverlay (Virtual D-Pad for 10-foot UI)                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   State, Parsers & Storage Layer                       │
│  ┌──────────────────┐  ┌─────────────────┐  ┌───────────────────────┐  │
│  │   AppContext     │  │   M3U Parser    │  │     XMLTV Parser      │  │
│  │   - Profiles     │  │   - Robust      │  │     - UTC normalizer  │  │
│  │   - Channels/Fav │  │     EXTINF      │  │     - Program mapping │  │
│  │   - Playlists    │  │   - Group/Logo  │  └───────────────────────┘  │
│  │   - Watch Stats  │  └─────────────────┘  ┌───────────────────────┐  │
│  └──────────────────┘                       │  localStorage Store   │  │
│                                             │  - JSON Backup Export │  │
│                                             │  - Schema Validation  │  │
│                                             └───────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Plano de Execução Imediato (Sequência de Implementação)

1. **Step 1: Criação do Componente de Confirmação In-App (`ConfirmModal.tsx`)**
   - Substituir diálogos nativos `window.confirm` em `SettingsView.tsx` e `PlaylistsView.tsx`.
2. **Step 2: Suporte HLS Completo no Multiview (`MultiViewTile.tsx`)**
   - Implementar renderizador com `hls.js` individual por slot no grid do Multiview.
3. **Step 3: Correção dos Listeners de Teclado no Player (`VideoPlayer.tsx`)**
   - Adicionar trava para ignorar eventos de teclado quando focados em elementos de formulário.
4. **Step 4: Validação e Sanitização de Backup (`storage.ts`)**
   - Adicionar checagem de tipos e campos obrigatórios no `importNebulaData`.
5. **Step 5: Polimento do Navbar e Fallbacks (`Navbar.tsx` & `CategoryChips.tsx`)**
   - Tratamento de erro de carregamento de avatar e restauração de aba ao limpar busca.
6. **Step 6: Verificação Final de Compilação e Teste E2E**
   - Executar `compile_applet` e validar ausência de regressões.
