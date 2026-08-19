// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Nebula IPTV';

  @override
  String get home => 'Início';

  @override
  String get channels => 'Canais';

  @override
  String get favorites => 'Favoritos';

  @override
  String get history => 'Histórico';

  @override
  String get settings => 'Configurações';

  @override
  String get search => 'Buscar';

  @override
  String get playlists => 'Fontes';

  @override
  String get epg => 'Programação';

  @override
  String get errorGeneric => 'Ocorreu um erro inesperado.';

  @override
  String get errorNetwork => 'Sem conexão com a internet.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get noContent => 'Nenhum conteúdo disponível.';

  @override
  String get loading => 'Carregando...';

  @override
  String get homeEmptyMessage => 'Importe uma playlist para começar';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguagePtBr => 'Português (BR)';

  @override
  String get settingsGeneral => 'Geral';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsExportImport => 'Dados';

  @override
  String get exportSuccess => 'Dados exportados com sucesso';

  @override
  String get importSuccess => 'Dados importados com sucesso';
}
