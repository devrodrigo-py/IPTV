# Nebula IPTV — Especificação do Projeto (v2.1)

## 1. Visão do Projeto

Nebula IPTV é um aplicativo multiplataforma desenvolvido em Flutter/Dart para reprodução e gerenciamento de conteúdos IPTV fornecidos pelo próprio usuário ou por provedores autorizados.

O aplicativo deve oferecer uma experiência moderna semelhante a plataformas de streaming, com foco em:

- TV ao vivo
- canais organizados por categorias
- favoritos
- histórico
- busca
- EPG
- reprodução de streams
- gerenciamento de fontes IPTV
- interface para desktop
- interface adaptada para Android TV
- navegação por controle remoto
- persistência local
- importação e exportação de dados do usuário

O projeto deve ser desenvolvido de forma incremental.

Não implementar funcionalidades de fases futuras antes da infraestrutura necessária estar pronta.

---

## 2. Princípios Fundamentais

### 2.1 Qualidade

O código deve priorizar:

- legibilidade
- manutenção
- testabilidade
- baixo acoplamento
- separação de responsabilidades
- reutilização
- tratamento consistente de erros
- performance
- acessibilidade
- previsibilidade de comportamento

Evitar soluções rápidas que criem dívida técnica.

Aplicar abstrações somente quando houver benefício arquitetural concreto.

---

## 3. Stack

| Camada | Escolha |
| --- | --- |
| Linguagem | Dart |
| Framework | Flutter |
| Estado | Riverpod com `riverpod_generator` |
| Persistência | SQLite via Drift |
| Navegação | GoRouter |
| Arquitetura | Clean Architecture + SOLID |
| UI | Material 3 com Design System próprio |
| Cliente HTTP | Dio |
| Player de vídeo | `media_kit` com backend libmpv |
| Logging | pacote `logger` |
| Cache de imagens | implementação própria via Dio + `path_provider` |
| Credenciais | armazenamento seguro da plataforma |
| Internacionalização | `flutter_localizations` + arquivos `.arb` |
| Geração de código | `build_runner` + `freezed` restrito a `data/models/` |

Não utilizar componentes ou bibliotecas adicionais quando a stack existente resolver adequadamente o problema.

---

## 4. Decisões Técnicas Fechadas

Estas decisões não devem ser reabertas durante a implementação.

Se alguma delas se mostrar tecnicamente inviável, deve ser criado um ADR antes da alteração.

### 4.1 Player de vídeo

Usar `media_kit` como implementação concreta de `VideoPlayerService`.

Motivo:

- suporte a Windows
- suporte a Android
- suporte a Android TV
- backend libmpv consistente
- redução da fragmentação entre plataformas

A camada de apresentação nunca deve depender diretamente de `media_kit`.

O domínio da aplicação deve interagir com uma abstração própria.

A abstração do player deve prever desde o início:

- inicialização
- reprodução
- pausa
- parada
- liberação de recursos
- volume
- estado de reprodução
- estado de buffering
- posição
- duração quando aplicável
- seleção de faixa de áudio
- seleção de legenda
- listagem de faixas disponíveis
- eventos de erro estruturados
- código e causa do erro
- eventos de desconexão
- possibilidade de reconexão

Mesmo funcionalidades utilizadas somente em fases posteriores devem estar representadas na interface quando forem parte fundamental do contrato do player.

### 4.2 Padrão de Result

Definir em `core/result/` uma sealed class:

```dart
sealed class Result<T> {}

final class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppFailure failure;
  Failure(this.failure);
}
```

Todo repository ou use case que possa falhar deve retornar `Result<T>`.

Nunca lançar exceções diretamente para a camada de apresentação.

Exceções de bibliotecas externas devem ser capturadas e convertidas para `AppFailure`.

### 4.3 Cliente HTTP e injeção de dependência

HTTP: Dio configurado em `core/network/` com:

- timeout de conexão
- timeout de leitura
- timeout de escrita
- interceptors
- logging seguro
- normalização de erros
- conversão de exceções para `Failure`

Nunca registrar: username, password, token, URL contendo credenciais, headers sensíveis.

Injeção de dependência: Riverpod. Providers devem expor services, datasources, repositories, use cases, controllers.

Não introduzir um segundo container de DI sem necessidade comprovada e ADR.

### 4.4 Timezone do EPG

Todo horário recebido por XMLTV deve ser convertido para UTC no momento do parse.

Persistência: UTC. Apresentação: timezone local do dispositivo.

Nunca comparar horários provenientes de fontes diferentes sem normalização prévia.

### 4.5 Estrutura de data/domain

As camadas `data/` e `domain/` são globais.

Não replicar `data/` e `domain/` dentro de cada feature.

`features/` representa apenas a camada de apresentação organizada por área funcional.

Caso uma feature cresça a ponto de justificar arquitetura interna independente, qualquer migração para feature-first exige ADR.

### 4.6 Geração de código

Freezed: utilizar somente em `data/models/` (DTOs Xtream, estruturas XMLTV, estruturas M3U, responses HTTP).

Não utilizar freezed em `domain/entities/`. Entidades de domínio devem permanecer classes Dart imutáveis escritas manualmente.

Riverpod Generator: usar em providers, controllers, dependências gerenciadas por Riverpod.

Build Runner: executar obrigatoriamente no CI. O código gerado deve permanecer commitado. O CI deve falhar caso build_runner produza alterações não commitadas.

### 4.7 Cache de imagens

Não utilizar `cached_network_image`.

Implementar cache próprio utilizando Dio, `path_provider`, armazenamento em disco, hash da URL como chave, política de expiração.

Falhas no cache não devem impedir a exibição do restante da interface.

### 4.8 Logging

Utilizar o pacote `logger`. Configurar em `core/logging/`.

Níveis: debug, info, warning, error.

Em release, logs verbosos devem ser desativados através de `LogFilter`.

Dados sensíveis nunca devem ser registrados.

### 4.9 Migrations Drift

Utilizar `schemaVersion` incremental. Primeira versão na Fase 3.

Utilizar `MigrationStrategy` explícita com `onCreate` e `onUpgrade`.

Regra permanente: uma migration já publicada ou commitada nunca pode ser editada.

### 4.10 Favoritos

Favoritos serão armazenados em tabela própria. `Channel` não terá `isFavorite` como source of truth.

```
Favorite
- id
- channelId
- createdAt
```

Constraint: `UNIQUE(channelId)`.

### 4.11 Identificação de canais

Cada canal terá `id` (local) e `sourceId` (externo, pode ser nulo).

Para Xtream: `sourceId = stream_id`. Para M3U: priorizar `tvg-id`.

Não usar exclusivamente `streamUrl` como identidade do canal.

### 4.12 Armazenamento de credenciais

Credenciais não devem ser armazenadas em texto puro no Drift.

O banco armazena somente referência (`credentialKey`).

Abstração:

```dart
abstract interface class CredentialStore {
  Future<Result<void>> save(...);
  Future<Result<String?>> read(...);
  Future<Result<void>> delete(...);
}
```

### 4.13 Fase 4 dividida em checkpoints

Fase 4A — M3U. Fase 4B — Xtream. Cada uma com seu próprio Definition of Done.

---

## 5. Plataformas

Prioridade 1: Windows, Android. Prioridade 2: Android TV. Futuro: iOS, macOS, Linux.

---

## 6. Arquitetura

Fluxo: UI → Provider/Controller → UseCase → Repository → DataSource

Estrutura:

```
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   └── bootstrap/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── result/
│   ├── theme/
│   ├── utils/
│   ├── cache/
│   ├── logging/
│   ├── credentials/
│   └── widgets/
├── features/
│   ├── home/
│   ├── channels/
│   ├── player/
│   ├── favorites/
│   ├── history/
│   ├── epg/
│   ├── playlists/
│   └── settings/
├── data/
│   ├── database/
│   │   ├── tables/
│   │   ├── daos/
│   │   └── migrations/
│   ├── datasources/
│   │   ├── m3u/
│   │   ├── xtream/
│   │   ├── epg/
│   │   └── credentials/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── services/
│   └── usecases/
└── main.dart
```

---

## 7. Regras de Código

SOLID aplicado pragmaticamente. Classes com responsabilidade clara. Widgets pequenos, sem lógica de negócio, sem acesso direto a banco/HTTP.

---

## 8. Tratamento de Erros

Falhas previstas: NetworkFailure, PlaylistParseFailure, DatabaseFailure, StreamUnavailableFailure, AuthenticationFailure, AccountExpiredFailure, ConnectionLimitFailure, EpgParseFailure, CacheFailure, CredentialFailure, UnknownFailure.

UI deve apresentar mensagens amigáveis. Nunca exibir stack traces, exception names, mensagens internas de biblioteca, credenciais ou URLs com credenciais.

---

## 9. Modelo de Dados

### 9.1 Playlist

```
Playlist: id, name, type, url, epgUrl, username, credentialKey, xtreamPortOverride, lastSyncAt, syncStatus, createdAt, updatedAt, isActive
```

PlaylistType: m3u, xtream, local. PlaylistSyncStatus: idle, syncing, error.

### 9.2 Channel

```
Channel: id, playlistId, sourceId, name, streamUrl, logoUrl, groupName, tvgId, tvgName, isActive, sourceType, createdAt, updatedAt
```

### 9.3 Favorite

```
Favorite: id, channelId, createdAt — UNIQUE(channelId)
```

### 9.4 EPG

```
EpgProgram: id, channelId, title, description, startTimeUtc, endTimeUtc, category, imageUrl
```

### 9.5 Histórico

```
WatchHistory: id, channelId, startedAt, lastWatchedAt, watchedDurationMs
```

---

## 10. Favoritos

Persistidos em SQLite. Preservados ao inativar canal. Recuperados automaticamente se canal reaparecer.

---

## 11. Importação M3U

Parser tolerante a variações. Fluxo: validar → interpretar → extrair → normalizar → determinar sourceId → detectar duplicações → persistir → reportar estatísticas.

---

## 12. Importação Xtream Codes

Fase 4B. Via player_api.php. Autenticação, categorias, live streams, montagem de URL. Falhas específicas: AccountExpiredFailure, ConnectionLimitFailure, AuthenticationFailure.

---

## 13. Serviço de Player

Interface VideoPlayerService com Result<void> nos métodos, streams de estado, buffer, erros, tracks. Reconexão com backoff exponencial.

---

## 14. Player UI

Play, pause, stop, volume, fullscreen, loading, buffer, erro, retry, info do canal, troca rápida.

---

## 15. Home

Seções adaptativas: Continuar assistindo, Favoritos, Ao vivo, Categorias, Programação, Recentes.

---

## 16. Busca

Por nome, grupo, categoria, tvg-id, tvg-name, EPG. Debounce obrigatório. Responsiva com milhares de canais.

---

## 17. Categorias

Derivadas das fontes. Não hardcodar.

---

## 18. EPG

XMLTV. Sincronização automática configurável (default 6h). Normalização UTC.

---

## 19. Atualização de Playlists

Refresh manual e periódico. Reconciliação por identificador estável. Canais removidos → isActive=false. Favoritos e histórico preservados.

---

## 20. Cache de Imagens

Logos e thumbnails EPG. Hash da URL como chave. Política de expiração configurável.

---

## 21. Android TV

D-pad, Enter, Back, Play/Pause. Foco sempre visível. Infraestrutura preparada na Fase 2.

---

## 22. Windows

Janela redimensionável, fullscreen, atalhos, mouse, layout responsivo.

---

## 23. Design System

Modern Streaming UI + Dark Interface + Glass/Surface Layers + Accent Color + Soft Borders + Subtle Shadows + Smooth Animations. Performance first.

---

## 24. Tema

Dark Mode padrão. Tokens centralizados: Background, Surface, Surface Elevated, Card, Primary, Secondary, Text Primary, Text Secondary, Divider, Error, Success, Warning.

---

## 25. Tipografia

Escala: Display, Headline, Title, Body, Label, Caption.

---

## 26. Responsividade

Mobile < 600, Tablet 600–1024, Desktop 1024+. TV com overscan e distância de visualização.

---

## 27. Animações

Discretas: entrada de página, expansão, foco, transições. Evitar animações contínuas ou pesadas.

---

## 28. Internacionalização

pt-BR desde a Fase 1. flutter_localizations + .arb. Nunca hardcodar strings visíveis.

---

## 29. Segurança

Nunca registrar/armazenar/exibir credenciais. Nunca realizar bypass de autenticação/DRM/controles de acesso.

---

## 30. Dados do Usuário — Import/Export

JSON. Nunca exportar senha em texto claro. Fontes autenticadas indicam necessidade de reautenticação.

---

## 31. Performance

Projetar para dezenas de milhares de canais. Listas virtualizadas, lazy loading, índices SQLite, cache, debounce.

### 31.1 Índices iniciais

Channel: playlistId, sourceId, tvgId, name, groupName, isActive. Favorite: channelId. EpgProgram: channelId, startTimeUtc. WatchHistory: channelId.

---

## 32. Testes

Prioridade: Unit → Repository → Parser → Widget → Integration. Partes críticas: parser M3U, reconciliação, repositories, migrations, Result mapping, EPG timezone, favoritos, credenciais, reconexão.

---

## 33. Testes M3U

Cobrir: vazia, inválida, header ausente, uma entrada, múltiplas, campos ausentes, ordem diferente, caracteres especiais, URLs inválidas, duplicações, arquivo grande, nomes com vírgulas, atributos desconhecidos.

---

## 34. Integração Contínua

1. build_runner + git diff --exit-code
2. dart format --set-exit-if-changed
3. flutter analyze
4. flutter test

---

## 35. Git

Commits semânticos: feat, fix, refactor, test, docs, chore.

---

## 36. Processo Obrigatório do Agente

Analisar → verificar → identificar → propor → implementar → gerar código → formatar → analisar → testar → corrigir → revisar → confirmar DoD.

### 36.1 ADR

Local: docs/decisions/. Formato: 0001-titulo.md. Conteúdo: contexto, decisão, alternativas, consequências.

---

## 37. Regra de Incrementalidade

Cada fase resulta em estado compilável, testável, navegável, funcional.

---

## 38. Fases

1. Foundation — 2. Shell — 3. Database — 4A. M3U — 4B. Xtream — 5. Channel Browser — 6. Player — 7. History — 8. EPG — 9. Android TV — 10. Polish

### 38.1 Definition of Done por Fase

Resultado funcional + formatter + analyzer + testes + build_runner + CI verde + ADRs + sem regressão.

---

## 39. Definition of Done por Feature

Código + arquitetura + erros + loading/empty/error/success states + responsividade + teclado + foco + testes + formatter + analyzer + docs.

---

## 40–46. Regras Gerais

Autonomia do agente (seguir spec, ADR para lacunas), regra de produto (sem telas vazias, estados completos), segurança e legalidade (cliente para fontes autorizadas), prioridades (estabilidade > reprodução > performance > UX > arquitetura > extensibilidade > efeitos visuais), fora de escopo (VOD, séries, cloud sync, download, gravação, timeshift, proxy, DRM bypass), estado inicial (começar pela Fase 1), objetivo final (app IPTV moderno, rápido, estável, profissional).
