# Auditoria da entrega inicial

Data: 23/09/2026. Avaliação dos arquivos presentes, sem consultar histórico ou diferenças do Git.

| Área | Estado observado | Decisão |
|---|---|---|
| Estado | Riverpod 2; estado efêmero de UI em StatefulWidget | Manter Riverpod, escopar assinaturas por seção |
| Fontes | M3U, Xtream Codes, XMLTV, TMDB/TVMaze; parsers em isolates nativos | Preservar parsers testados; tipar o catálogo de apresentação |
| Player | media_kit nativo, video_player web; hardware decode configurado | Manter motor; corrigir reconexões concorrentes e ciclo de vida |
| D-pad | Focus nativo, policy espacial e grids por índice | Refazer carrosséis e hero: wrappers focáveis sem ação, Ver todos sem saída e Back capturado |
| Arquitetura | core/data/domain/features, Drift e Result; SQL e Maps ainda na UI/provedores | Nova home com repositório/modelos e providers granulares; migração por fronteira |
| UX | Home existente, perfis, detalhes, EPG separado | Reconstruir descoberta; distinguir loading/erro/vazio, metadados e Minha lista reativa |
| Performance | Grids lazy, cache em disco próprio; I/O síncrono no cache, hero sem cache fora de TV | Extensões fixas nos carrosséis, cache assíncrono, imagens com decode limitado |
| Busca | Debounce 300 ms, consultas locais + fallback remoto | Impedir resultado obsoleto e mostrar resultado local antes da rede |
| Qualidade | Testes de parser/banco/foco; CI fatal-infos; depreciações globalmente ignoradas | Cobrir os bugs observados e remover supressões globais quando viável |

Não há evidência obtida em dispositivo físico que permita atribuir crashes ao motor de vídeo ou afirmar fluidez no Fire Stick. Esses critérios exigem medição em profile/release e streams autorizados.

## Dependências

As restrições mínimas do pubspec são antigas; elas não equivalem às versões resolvidas. Conferir pubspec.lock e `flutter pub outdated`. Riverpod 2, go_router 14, media_kit_video 1 e flutter_lints 4 precisam de avaliação de atualização. `riverpod_annotation` não é usado com geração de providers. Não substituir o motor só por haver versão nova.

Referências primárias consultadas: [media_kit](https://pub.dev/packages/media_kit), [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [Flutter lints](https://pub.dev/packages/flutter_lints), [SQLite libs](https://pub.dev/packages/sqlite3_flutter_libs).

## Fases

1. Produto: home orientada ao catálogo, destaque, continuar, lista e categorias; estados explícitos.
2. Controle: um foco por ação, travessia lazy, menus, Back e restauração de foco; testes de controle remoto.
3. Performance/reprodução: cache, reconexão cancelável, sessões e testes de falhas.
4. Arquitetura/qualidade: fronteiras tipadas, logs, lint, suíte, documentação e medição reproduzível.

As fases serão registradas no CHANGELOG como partes da entrega inicial, sem usar o histórico Git como baseline.
