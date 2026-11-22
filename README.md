# Noticeboard V2

Based on [Noticeboard Mobile App](https://github.com/IMGIITRoorkee/noticeboard-mobile-app). The original app and design are credited to the Information Management Group (IMG) team at IIT Roorkee.

Browse Channel i notices on Android, bookmark what matters, and get alerts when notices are posted or updated.

## Install on Android

1. Download the APK from [GitHub Releases](https://github.com/HUKA-Taro/noticeboardv2/releases/latest) and open it on your phone.
2. Sign in with your Channel i account and allow notifications if you want alerts.

If you installed a V2 debug build, uninstall it before installing the release APK. GitHub restricts downloads to users with repository access while the repository is private.

Your installed version is shown at the bottom of **Profile**. Tap **Check for updates** to see if a newer public release is available.

## Features

- Search and filter notices, browse the placement and internship feed, and save bookmarks.
- Open a notice with “shortlist” in its title or body, then choose **Show student profiles** from the overflow menu. Recognized enrollment numbers link to Channel i profiles. Branch and year appear when the signed-in account can retrieve them. Scanned documents and images require a manual lookup.
- Receive alerts for new and updated notices, including while the app is open.

## Notification settings

Open **Profile → Notification settings** to manage alerts and see the checker’s status. The status refreshes every 30 seconds while this screen is open. You can also tap the refresh icon.

Automatic alerts depend on the [Channel i checker](https://github.com/HUKA-Taro/channeli-checker) reaching the feeds and sending pushes through Firebase Cloud Messaging. An online checker can still show that a feed is unready. Contact [HUKA_Taro](https://github.com/HUKA-Taro) if you want to host the checker. The notice alerts switch controls both new and updated notices.

Android can display alerts after you swipe the app away from Recents. If you force-stop the app in Android settings, reopen it to resume delivery.

## Build locally

Install Flutter and the Android SDK. Register `com.huka.taro.noticeboardv2` as an Android app in your Firebase project and put its `google-services.json` in `noticeboard/android/app/`. Your checker must send to the same Firebase project to deliver pushes to your build.

```sh
cd noticeboard
flutter pub get
flutter build apk --debug
```

Find the APK at `build/app/outputs/flutter-apk/app-debug.apk` relative to the Flutter project directory.

Android debug builds offer **Test notification now** and **Test notification in 30 seconds** in Profile. These test local display. Use a checker push to test delivery through Firebase.