import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current destination of the application shell.
final shellNavigationProvider = StateProvider<int>((ref) => 0);
