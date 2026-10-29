import 'google_oauth_stub.dart'
    if (dart.library.js_interop) 'google_oauth_web.dart' as platform;

class GoogleOAuthService {
  static const String clientId = '318616334957-3erbcd2rp1ui5ekqvsis28hoiufo7ier.apps.googleusercontent.com';

  /// Triggers the real Google OAuth 2.0 Account Chooser Popup on Web.
  /// Returns a Map with {idToken, email, name, picture, hd} if user signs in, or null.
  static Future<Map<String, dynamic>?> signInWithGooglePopup() async {
    return await platform.triggerGoogleOAuthPopup();
  }
}
