# Noticeboard V2

Noticeboard V2 is an unofficial, substantially modified Android app based on [IMG's original Noticeboard Mobile App](https://github.com/IMGIITRoorkee/noticeboard-mobile-app). The original app and its design are credited to the Information Management Group (IMG), IIT Roorkee.

This fork keeps the original Channel i noticeboard experience and adds tools for finding shortlist information, custom push alerts, backend status, and supported-version checks.

## What the app includes

### Noticeboard features

- Browse Channel i notices, search and filter the notice feed, and bookmark notices.
- Open notices in the app and use **Find in notice** to search the open notice. Matching text is highlighted, and the arrows move between matches. This also works on shortlist content shown in the notice.
- Detect notices whose title or body contains **shortlist** and offer shortlist tools from the notice menu.
- In shortlist notices, link recognized enrollment numbers to their Channel i student profiles. Choose **Show student profiles** to display available branch and year details alongside the links.
- Choose **Show counts** to see recognized students, room totals when rooms are listed, and branch totals as profile lookups complete. Counts are based on the entries the app can recognize in that notice.

Shortlist parsing depends on the notice's labels and table layout. Some differently formatted entries may not be recognized. Branch and year lookups require a valid signed-in session and a successful Channel i People Search response.

### Notifications

- Receive push alerts for new and updated notices through Firebase Cloud Messaging (FCM), including while Noticeboard V2 is open.
- Control the **New and updated notices** alert in **Profile > Notification settings**. Alerts are enabled by default; Android notification permission is still required.
- Check whether the custom notification checker is online and whether its notice feed is ready. The status refreshes every 30 seconds while the settings screen is open; you can also refresh it manually.
- Use **Send test notification** in notification settings to check that Android can display an alert on this device. It creates a local test alert; it does not test the checker or prove that a remote push was delivered.

Automatic push alerts depend on the separate [Channel i checker](https://github.com/HUKA-Taro/channeli-checker). It checks the supported Channel i feeds and sends FCM notifications when it detects a new or updated notice. If the checker is stopped, cannot reach Channel i, or cannot send through Firebase, automatic notice alerts may be delayed or unavailable. The app can still be used to browse notices when the checker is offline.

Android may deliver notifications after the app is swiped away from Recents. If Android's app settings are used to force-stop Noticeboard V2, reopen the app to resume notification delivery.

### App updates

- On Android startup, the app checks the minimum supported build policy stored in Firestore. If this installation is below the required build, the app asks you to install the required release before continuing. A previously cached policy can be used if Firestore cannot be reached.
- **Profile** shows the installed app version and lets you check the policy again. When an update is required, the app opens the release APK download; Android asks you to confirm the installation. The app cannot silently install an APK.

The version policy and APK download link must be kept current when a release is published. The update flow depends on the Firestore policy being available and the release APK being downloadable.

## Install

1. Download the signed Android APK from the [GitHub Releases](https://github.com/HUKA-Taro/noticeboardv2/releases) page.
2. Open the APK on your Android phone and approve installation if prompted.
3. Sign in with your Channel i account and allow notifications if you want alerts.

## Build locally

Install Flutter and the Android SDK, configure the Android app with the correct Firebase project, and configure the local release signing key. Then run:

```sh
flutter pub get
flutter build apk --release
```

The signed APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Set the app version in `pubspec.yaml` before building. When publishing a release, keep the release tag, APK filename, and app version consistent. Do not commit the local signing key or `android/key.properties`.

## Credits

- Original app and design: [Information Management Group (IMG), IIT Roorkee](https://github.com/IMGIITRoorkee/noticeboard-mobile-app).
- Noticeboard V2 modifications: HUKA_Taro.
