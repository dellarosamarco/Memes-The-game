// Dev only: exposes the fight state to the browser (window.memesState) so
// automated play-tests can read it. Enabled with --dart-define=MEMES_DEBUG=true.
export 'debug_bridge_stub.dart'
    if (dart.library.js_interop) 'debug_bridge_web.dart';
