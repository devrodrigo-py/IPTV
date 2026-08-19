import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/theme/app_theme.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';

void main() {
  group('FocusableWidget', () {
    testWidgets('should call onPressed on tap', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: FocusableWidget(
              onPressed: () => pressed = true,
              builder: (context, isFocused) =>
                  const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FocusableWidget));
      expect(pressed, isTrue);
    });

    testWidgets('should call onPressed on Enter key', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: FocusableWidget(
              autofocus: true,
              onPressed: () => pressed = true,
              builder: (context, isFocused) =>
                  const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, isTrue);
    });

    testWidgets('should show focus indicator when focused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: FocusableWidget(
              autofocus: true,
              builder: (context, isFocused) => Container(
                width: 100,
                height: 50,
                color: isFocused ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The builder should receive isFocused=true
      final container = tester.widget<Container>(find.byType(Container).last);
      expect((container.color), Colors.blue);
    });
  });
}
