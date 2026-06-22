# Habit Tracker

A simple, elegant habit tracker for Android, built with Flutter.

## Features
- Add habits and check them off daily
- Automatic streak tracking (🔥)
- Local persistence (your data stays on the device)
- Material 3 UI with light/dark mode
- Swipe-to-delete

## How it's built
This repo builds itself in the cloud via **GitHub Actions** — no local toolchain required.

On every push to `main` (or via the **Actions → Build Android APK → Run workflow** button), GitHub:
1. Sets up Java + Flutter
2. Generates the Android project scaffold (`flutter create`)
3. Applies the app source from `app_src/`
4. Builds a release APK
5. Uploads it as a build **artifact** and publishes a **GitHub Release**

## Install on your phone
1. Open the [Releases](../../releases) page (or the latest Actions run → Artifacts).
2. Download `app-release.apk`.
3. On your Android phone, enable "Install unknown apps" for your browser/file manager.
4. Open the APK to install.

> Note: This is an unsigned/debug-style release APK intended for personal sideloading,
> not for Google Play distribution.

## Project layout
```
app_src/
  main.dart      # the app
  pubspec.yaml   # dependencies
.github/workflows/build.yml   # CI build pipeline
```
