# Nebula IPTV

Player de IPTV com cara de serviço de streaming, feito para TV: Amazon Fire TV / Fire Stick, Google TV / Android TV e Xiaomi Mi Box / Mi TV. Também roda no navegador.

O Nebula **não fornece conteúdo**. Ele organiza e reproduz as listas que o usuário já tem (M3U/M3U8 ou login Xtream Codes do provedor).

## O que ele faz

- **Ao vivo, filmes e séries** a partir de um login Xtream Codes (`player_api.php`) ou de uma lista M3U. Em listas M3U, filmes (`/movie/`, `.mp4`, `.mkv`…) e episódios (`S01E02`) são separados automaticamente.
- **Home estilo streaming**: o fundo e a sinopse do topo acompanham o título em foco (e giram sozinhos quando parado), *Continuar assistindo* com barra de progresso, *Minha lista*, Top 10 com numerais, adicionados recentemente, séries e prateleiras por categoria.
- **Minha lista** por perfil e tela **"Quem está assistindo?"** ao abrir.
- **Busca por voz** no Google TV / Android TV (usa o reconhecimento de fala do sistema).
- **Retomar de onde parou**, "assistir do início", próximo episódio automático e marcação de episódios vistos.
- **Guia de programação (EPG)**: baixado automaticamente da lista (`url-tvg`) ou do servidor Xtream (`xmltv.php`, aceita `.gz`), com processamento fora da thread principal.
- **Player nativo no Android (Media3/ExoPlayer)**: HLS, MPEG-TS, MP4/MKV, HEVC, áudio Dolby (AC3/EAC3), escolha de faixa de áudio e legenda, reconexão automática, troca de canal com CH+/CH-, setas e teclado numérico.
- **Controle remoto**: menu lateral recolhido que se expande ao receber foco, foco sempre visível, navegação de fileira em fileira pelo D-pad, Voltar hierárquico (fecha player → modal → volta ao Início → menu → sai do app), teclas de mídia.
- **Listas enormes**: catálogo no IndexedDB (sem o limite de ~5 MB do localStorage) e grades renderizadas aos poucos.
- **Modo leve** automático em aparelhos de entrada (Fire TV Stick): menos blur, sombras e animações. A multitela é limitada ao que o aparelho decodifica.
- Perfis com PIN, perfil Kids, estatísticas, backup/restauração.
- Capas e sinopses opcionais via **TMDB** (chave gratuita em Configurações).

## Desenvolvimento

```bash
npm install
npm run dev        # http://localhost:3000
npm test           # testes unitários (Vitest)
npm run lint       # checagem de tipos
npm run build      # build web em dist/
```

No navegador, a maioria dos servidores IPTV bloqueia requisições (CORS). Para testar listas reais no navegador, configure um proxy em **Configurações → Proxy CORS**. O app Android não precisa disso.

## App Android TV

O projeto Android fica em `android/` (Capacitor 7). O player nativo está em `android/app/src/main/java/app/nebula/iptv/player/`.

### Baixar o APK pronto

Cada pull request e cada push na `main` gera um APK de depuração: **GitHub → Actions → CI → execução → Artifacts → `nebula-iptv-debug-apk`**.

### Compilar localmente

Requisitos: Node 22, JDK 21 e Android SDK (Android Studio).

```bash
npm run android:apk
# APK em android/app/build/outputs/apk/debug/app-debug.apk
```

Para um APK de produção assinado, defina `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD` e rode `./gradlew assembleRelease` em `android/`.

### Instalar na TV

**Fire TV / Fire Stick**
1. *Configurações → Minha Fire TV → Opções do desenvolvedor*: ative a depuração ADB e a instalação de apps de origem desconhecida.
2. Use o app *Downloader* com o link do APK, ou pelo computador: `adb connect IP_DA_TV` e `adb install -r app-debug.apk`.

**Google TV / Android TV / Xiaomi Mi Box**
1. Ative as *Opções do desenvolvedor* (toque 7 vezes em *Sobre → Build do Android TV OS*) e a *Depuração USB/ADB*.
2. `adb connect IP_DA_TV` e `adb install -r app-debug.apk`, ou instale com um gerenciador de arquivos.

O app aparece na fileira de apps da TV com o banner do Nebula.

Compatibilidade:
- Android 6.0 ou mais novo (minSdk 23): Fire TV Stick 2ª geração em diante (Fire OS 6+), Google TV, Android TV, Mi Box / Mi TV. Fire OS 5 não é suportado pelo Capacitor 7.
- Funciona mesmo com WebView antiga e sem atualização (testado com a WebView 66 de um Android TV 9): o código é convertido para Chrome 64+ e o CSS não depende de recursos recentes.
- A interface é desenhada em 1280 px de largura lógica dentro do app de TV (escala de leitura a 3 m da tela) e o player é nativo (Media3), então o desempenho de vídeo não depende da WebView.
- Fontes, logo e avatares vão dentro do app: nada depende de serviços externos para abrir.

### Teclas do controle no player

| Tecla | Ao vivo | Filmes e séries |
|---|---|---|
| CH+ / CH- (ou ↑ / ↓ com os controles ocultos) | troca de canal | — |
| Números | vai para o canal digitado | — |
| ← / → (controles ocultos) | — | volta / avança 10 s |
| OK | mostra os controles (áudio, legendas, qualidade) | idem |
| Voltar | esconde os controles; de novo, sai do player | idem (salva a posição) |

## Publicação em lojas

A Amazon Appstore e o Google Play aceitam players de IPTV que **não** incluem nem divulgam canais. Por isso, o app começa vazio, mostra o aviso "traga sua própria lista" e só carrega a demonstração (streams públicos de teste) se o usuário pedir. Não adicione listas, logos de canais ou marcas de terceiros ao material da loja.

## Marca e design

- **Marca**: um planeta com o botão de play no núcleo e uma órbita no degradê nebulosa (violeta → magenta → âmbar), com o nome "nebula" em minúsculas (Outfit Bold). A fonte única do símbolo é `src/components/brand/markSvg.ts`.
- **Assets gerados** a partir dela (favicon, ícones do launcher, banner da Android TV, telas de abertura, marca do player): `npx vite-node scripts/generate-brand.ts`.
- **Paleta**: pretos e cinzas neutros com um único acento violeta (`#7C5CFF`). Arte em primeiro lugar: pôsteres sem bordas nem texto, com cartão tipográfico quando o provedor não manda imagem.
- **TV**: layout lógico de 1280 px, menu lateral recolhido, destaque fixo no topo da Início descrevendo o título em foco, foco por ampliação com anel duplo (fresta escura + borda branca).

## Estrutura

```
src/
  context/AppContext.tsx   estado global, sincronização de listas, reprodução
  data/                    Xtream, M3U, XMLTV, EPG, progresso, IndexedDB, TMDB
  platform/                detecção de aparelho, HTTP nativo, ponte do player nativo e do controle
  components/ views/       interface
android/                   app Android TV (Capacitor + Media3)
```
