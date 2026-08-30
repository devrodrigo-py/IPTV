# Nebula IPTV

Player IPTV multiplataforma (Windows, Android TV/Fire TV, tablet, web) com
M3U + Xtream Codes API, EPG XMLTV, VOD/séries, deduplicação de canais,
metadados TMDB/TVMaze e perfil parental.

> **Fonte da verdade de produto**: [`docs/spec.md`](docs/spec.md) (v2.1) e
> [`docs/decisions/`](docs/decisions/) (ADRs). Não há outro documento de
> design vigente.

## Plataformas suportadas

| Plataforma | Estado |
|---|---|
| Windows | ✅ primária |
| Android (TV/Fire TV/tablet) | ✅ primária — APKs split por ABI |
| Web | ⚠️ experimental — credenciais em memória, player degradado |

## Desenvolvimento

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen
flutter analyze                                            # 0 issues esperado
flutter test                                               # ~223 testes
flutter run -d windows                                     # desktop
```

## Release (Android)

Assinatura: `android/nebula-release.jks` + `android/key.properties`
(**fora do git** — ver `.gitignore`). Sem o arquivo, o build cai para a
chave de debug (só útil em dev).

```bash
flutter build apk --release --split-per-abi   # armeabi-v7a / arm64-v8a / x86_64
```

O keystore é a identidade do app: **perder impede updates por cima**.
Backup seguro do `.jks` e das senhas é obrigatório.

Release checklist (resumo — detalhes no relatório de produção na conversa):
versão bumpada no `pubspec.yaml`, `flutter analyze` zerado, suíte verde,
APK testado em dispositivo real, changelog da mensagem de commit.

## Arquitetura (30 segundos)

- **UI** (features/*) → **providers** (Riverpod puro) → **repositories**
  (Result tipado) → **datasources** (Dio/Drift/isolates) → **SQLite** (Drift,
  migrações incrementais em `app_database.dart`).
- Parse pesado (M3U/Xtream/XMLTV) roda em isolates.
- Credenciais de painéis: cofre seguro por plataforma (`CredentialStore`),
  nunca em texto no banco; logs sanitizados.
- TLS: reject por padrão, opt-in por fonte com aviso (ADR-005).
- Erros: handlers globais em `main.dart` + log de crash em arquivo
  (`CrashLogService`).
