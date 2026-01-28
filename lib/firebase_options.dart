import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return web; // Use web config for Windows
      case TargetPlatform.linux:
        return web; // Use web config for Linux
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDhepqv23-Rx4ZOfWwu8wtKkwx2m7zbs00',
    appId: '1:415888851556:web:e76d576b1af12a75e19571',
    messagingSenderId: '415888851556',
    projectId: 'keto-meal-builder',
    authDomain: 'keto-meal-builder.firebaseapp.com',
    storageBucket: 'keto-meal-builder.firebasestorage.app',
    measurementId: 'G-VVL90729CK',
  );

  // Placeholder for Android - configure in Firebase Console if needed
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhepqv23-Rx4ZOfWwu8wtKkwx2m7zbs00',
    appId: '1:415888851556:web:e76d576b1af12a75e19571',
    messagingSenderId: '415888851556',
    projectId: 'keto-meal-builder',
    storageBucket: 'keto-meal-builder.firebasestorage.app',
  );

  // Placeholder for iOS - configure in Firebase Console if needed
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDhepqv23-Rx4ZOfWwu8wtKkwx2m7zbs00',
    appId: '1:415888851556:web:e76d576b1af12a75e19571',
    messagingSenderId: '415888851556',
    projectId: 'keto-meal-builder',
    storageBucket: 'keto-meal-builder.firebasestorage.app',
    iosBundleId: 'com.example.mealPlannerAppLocalVersion',
  );

  // Placeholder for macOS - configure in Firebase Console if needed
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDhepqv23-Rx4ZOfWwu8wtKkwx2m7zbs00',
    appId: '1:415888851556:web:e76d576b1af12a75e19571',
    messagingSenderId: '415888851556',
    projectId: 'keto-meal-builder',
    storageBucket: 'keto-meal-builder.firebasestorage.app',
    iosBundleId: 'com.example.mealPlannerAppLocalVersion',
  );
}
