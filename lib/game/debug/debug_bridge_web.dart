import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Makes `window.memesState()` return the JSON produced by [state] and
/// `window.memesCmd(name)` run [command].
void publishDebugState(
  String Function() state, [
  void Function(String)? command,
]) {
  globalContext['memesState'] = (() => state().toJS).toJS;
  if (command != null) {
    globalContext['memesCmd'] = ((JSString name) => command(name.toDart)).toJS;
  }
}
