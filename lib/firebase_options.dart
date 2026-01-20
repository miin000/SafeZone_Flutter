// File generated manually - Firebase configuration options

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
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCagOnfqUj8wF5iTf0zCcIsFIV0_feuXzo',
    appId: '1:69642253810:web:f3f08500b89f090498a76b',
    messagingSenderId: '69642253810',
    projectId: 'safezone-afe7f',
    authDomain: 'safezone-afe7f.firebaseapp.com',
    storageBucket: 'safezone-afe7f.firebasestorage.app',
    measurementId: 'G-B07NPBM2GB',
  );

  // Android configuration - update with your google-services.json values
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCagOnfqUj8wF5iTf0zCcIsFIV0_feuXzo',
    appId: '1:69642253810:android:YOUR_ANDROID_APP_ID', // Update this
    messagingSenderId: '69642253810',
    projectId: 'safezone-afe7f',
    storageBucket: 'safezone-afe7f.firebasestorage.app',
  );

  // iOS configuration - update with your GoogleService-Info.plist values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCagOnfqUj8wF5iTf0zCcIsFIV0_feuXzo',
    appId: '1:69642253810:ios:YOUR_IOS_APP_ID', // Update this
    messagingSenderId: '69642253810',
    projectId: 'safezone-afe7f',
    storageBucket: 'safezone-afe7f.firebasestorage.app',
    iosBundleId: 'com.example.mobileFlutter', // Update this
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCagOnfqUj8wF5iTf0zCcIsFIV0_feuXzo',
    appId: '1:69642253810:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '69642253810',
    projectId: 'safezone-afe7f',
    storageBucket: 'safezone-afe7f.firebasestorage.app',
    iosBundleId: 'com.example.mobileFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCagOnfqUj8wF5iTf0zCcIsFIV0_feuXzo',
    appId: '1:69642253810:web:f3f08500b89f090498a76b',
    messagingSenderId: '69642253810',
    projectId: 'safezone-afe7f',
    authDomain: 'safezone-afe7f.firebaseapp.com',
    storageBucket: 'safezone-afe7f.firebasestorage.app',
    measurementId: 'G-B07NPBM2GB',
  );
}
