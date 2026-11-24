# Noticeboard V2

Based on [Noticeboard Mobile App](https://github.com/IMGIITRoorkee/noticeboard-mobile-app). The original app and design are credited to the Information Management Group (IMG) team at IIT Roorkee.

Browse Channel i notices on Android, bookmark what matters, and get alerts when notices are posted or updated.

## Install on Android

1. Open the signed release APK on your phone and follow Android's installation prompts.
2. Sign in with your Channel i account and allow notifications if you want alerts.

Your installed version is shown at the bottom of **Profile**. On launch, the app checks the required build published by the Channel i checker. If an update is required, the app opens the official APK download when you tap **Install latest version**. Android asks you to confirm the installation.

## Features

- Search and filter notices, browse the placement and internship feed, and save bookmarks.
- Open a notice with “shortlist” in its title or body, then choose **Show student profiles** from the overflow menu. Recognized enrollment numbers link to Channel i profiles. Branch and year appear when the signed-in account can retrieve them.
- Choose **Show counts** in a shortlist notice to see unique recognized students, room counts when available, and branch counts as profiles load.
- Receive alerts for new and updated notices, including while the app is open.

## Notification settings

Open **Profile → Notification settings** to manage alerts.

Automatic alerts depend on the [Channel i checker](https://github.com/HUKA-Taro/channeli-checker) reaching the feeds and sending pushes through Firebase Cloud Messaging. Contact [HUKA_Taro](https://github.com/HUKA-Taro) if you want to host the checker. The notice alerts switch controls both new and updated notices.

The status row on this page checks the checker's public heartbeat every 30 seconds and reports whether it is online and whether the notice feed is ready.

**Send test notification** shows a local notification. If Android blocks notifications, the app will ask for permission or direct you to Android settings.

Android can display alerts after you swipe the app away from Recents. If you force-stop the app in Android settings, reopen it to resume delivery.

## Build locally

Install Flutter and the Android SDK. Register `com.huka.taro.noticeboardv2` as an Android app in your Firebase project and put its `google-services.json` in `android/app/`. Your checker must send to the same Firebase project to deliver pushes to your build.

```sh
flutter pub get
flutter build apk --release
```

The Android project builds the release variant only. Find the signed APK at `build/app/outputs/flutter-apk/app-release.apk`. Configure `android/key.properties` locally with the existing release signing key for this app. Keep the properties file and signing key out of Git. Keep the app repository and release asset public while using the built-in update flow.

Publish the APK as `noticeboardv2-2.1.0.apk` under tag `v2.1.0`. Keep the tag and app version in sync. Publish only once the signed APK is ready. The checker reads both app release repos and makes that build required.
