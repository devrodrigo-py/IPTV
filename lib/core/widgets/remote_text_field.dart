import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';

/// D-pad focus highlights a field; only OK opens the keyboard.
class RemoteTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool autofocus;
  const RemoteTextField(
      {super.key,
      this.controller,
      this.focusNode,
      this.onChanged,
      this.style,
      this.decoration,
      this.autofocus = false});
  @override
  State<RemoteTextField> createState() => _RemoteTextFieldState();
}

class _RemoteTextFieldState extends State<RemoteTextField> {
  final _entry = FocusNode(debugLabel: 'Search entry');
  final _editor = FocusNode(debugLabel: 'Search editor');
  bool _editing = false;
  FocusNode get _entryNode => widget.focusNode ?? _entry;
  @override
  void dispose() {
    _entry.dispose();
    _editor.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _editor.requestFocus();
    });
  }

  void _finish() {
    setState(() => _editing = false);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _entryNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tv = PlatformDetector.isTv(context);
    if (!tv) {
      return TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          style: widget.style,
          decoration: widget.decoration,
          autofocus: widget.autofocus);
    }
    return PopScope(
        canPop: !_editing,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _editing) _finish();
        },
        child: Focus(
            canRequestFocus: false,
            onKeyEvent: (node, event) {
              if (_editing && RemoteKeys.isBack(event.logicalKey)) {
                if (event is KeyDownEvent) _finish();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FocusableWidget(
              focusNode: _entryNode,
              autofocus: widget.autofocus,
              onPressed: _start,
              canRequestFocus: !_editing,
              builder: (context, focused) => TextField(
                controller: widget.controller,
                focusNode: _editor,
                canRequestFocus: _editing,
                readOnly: !_editing,
                onTap: _editing ? null : _start,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _finish(),
                onChanged: widget.onChanged,
                style: widget.style,
                decoration: widget.decoration,
              ),
            )));
  }
}
