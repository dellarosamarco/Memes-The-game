import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Makes `window.memesState()` return the JSON produced by [state].
void publishDebugState(String Function() state) {
  globalContext['memesState'] = (() => state().toJS).toJS;
}
