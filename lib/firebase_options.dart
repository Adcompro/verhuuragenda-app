// Placeholder values — Codemagic overwrites this from
// GoogleService-Info.plist before each build. Local Flutter builds
// without CI keep the placeholders; Firebase.initializeApp will throw,
// PushService catches it, and the rest of the app still runs.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => ios;

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-PLACEHOLDER',
    appId: '1:PLACEHOLDER:ios:PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'placeholder',
    storageBucket: 'placeholder.appspot.com',
    iosBundleId: 'nl.verhuurvakantiewoning.app',
  );
}
