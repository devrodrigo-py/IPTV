# Nebula IPTV (Web / React)

Nebula IPTV é uma plataforma moderna e elegante para reprodução e gerenciamento de transmissões IPTV (Live TV, VOD e Séries), reescrita em **React + TypeScript + Vite + Tailwind CSS**.

## ✨ Principais Funcionalidades

- **Canais Ao Vivo (Live TV)**:
  - Grade e lista com logotipos, resolução (4K, FHD, HD) e status ao vivo.
  - Sintonizador com Hls.js (.m3u8) e fallback nativo.
  - Indicador dinâmico de programa atual e barra de progresso EPG.
  - Gaveta de canais rápidos (Quick Channel Drawer) dentro do player.
  - Ajuste de proporção (16:9, 4:3, Fill, Fit), qualidade de stream e Picture-in-Picture (PiP).

- **Multiview Wall**:
  - Reprodução simultânea de 2, 4 (2x2) ou 9 (3x3) transmissões.
  - Controle de foco de áudio dinâmico por tile.
  - Adição e troca rápida de canais por slot.

- **Filmes sob Demanda (VOD) & Séries**:
  - Catálogo categorizado com capas, sinopse, elenco, nota e ano.
  - Navegação de séries por temporadas e lista de episódios.

- **Guia Eletrônico de Programação (EPG)**:
  - Linha do tempo de canais sincronizada em UTC e adaptada ao fuso local.
  - Importação de arquivos XMLTV (.xml/.xmltv).

- **Gerenciamento de Listas (Playlists)**:
  - Suporte a links M3U / M3U8 web.
  - Upload direto de arquivo local M3U / M3U8 com parser tolerante.
  - Integração com servidores Xtream Codes API.
  - Ativação/desativação individual e recarga de listas.

- **Perfis de Usuário & Proteção Parental**:
  - Suporte a múltiplos perfis (ex: Principal, Cinema, Kids).
  - Bloqueio por senha/PIN de 4 dígitos.
  - Modo Kids com filtragem automática de canais adultos.

- **Modo TV (10-Foot UI)**:
  - Navegação adaptada para controle remoto e teclas direcionais do teclado (D-Pad).
  - Anéis de foco luminosos com gradiente Nebula.
  - Overlay de controle remoto virtual na tela.

- **Nebula Wrapped & Estatísticas**:
  - Métricas de horas assistidas, dias ativos e ranking de canais mais sintonizados.
  - Retrospectiva interativa no estilo Wrapped com cartões de estatísticas e personalidade.

- **Persistência & Backups**:
  - Armazenamento em `localStorage` com exportação e importação completa em JSON.

## 🚀 Como Executar

```bash
# Instalar dependências
npm install

# Iniciar servidor de desenvolvimento (porta 3000)
npm run dev

# Gerar build de produção
npm run build
```
