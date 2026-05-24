# Poster App (Flutter)

Poster maker for the Roman Catholic Diocese of Cochin. Opens to a **menu**; choose **Birthday Poster** for the clergy birthday layout (same as the web `index.html` editor).

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install).
2. Copy your poster template image into `assets/poster_background.jpeg`  
   (from the parent folder, e.g. `1001257979.jpeg`). A copy may already be there if that file exists next to `index.html`.
3. Generate platform folders (first time only), then run:

```bash
cd birthday_poster_app
flutter create . --project-name birthday_poster_app
flutter pub get
flutter run
```

On first run, allow photo/gallery access when picking a portrait.

## Build APK without installing Flutter

You cannot compile a Flutter APK on your PC without the Flutter SDK. Use **free GitHub Actions** instead:

1. Create a free account at [github.com](https://github.com) if you do not have one.
2. Create a new repository (e.g. `birthday-poster`).
3. Upload this whole `pstr` folder (or at least `birthday_poster_app/` plus `.github/workflows/build-apk.yml`).
4. On GitHub, open **Actions** → **Build APK** → **Run workflow** (or push any change to trigger it).
5. When the run finishes (about 5–10 minutes), open the run → **Artifacts** → download **birthday-poster-apk.zip** → unzip → install `app-release.apk` on Android.

On your phone you may need to allow **Install from unknown sources** for the file manager or browser you use.

### Other options

- Ask someone with Flutter installed to run `flutter build apk` in `birthday_poster_app`.
- Use [Codemagic](https://codemagic.io) (free tier): connect the repo and build Android APK in the cloud.

## Features

- Edit date, designation, given name, family name, and church positions
- Upload and position a portrait photo
- Live poster preview
- Export PNG or JPEG and share/save via the system share sheet
