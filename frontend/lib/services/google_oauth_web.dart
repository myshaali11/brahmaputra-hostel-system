import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

@JS('launchGoogleSignIn')
external JSPromise<JSString> _launchGoogleSignIn();

Future<Map<String, dynamic>?> triggerGoogleOAuthPopup() async {
  try {
    final jsPromise = _launchGoogleSignIn();
    final jsString = await jsPromise.toDart;
    final dartString = jsString.toDart;
    final data = jsonDecode(dartString) as Map<String, dynamic>;
    return data;
  } catch (e) {
    rethrow;
  }
}
