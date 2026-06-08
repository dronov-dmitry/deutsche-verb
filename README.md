# Deutsche Verb

Fully offline Flutter app for learning German verbs. No server, no login, no internet required.

## Features

- **~3000 verbs** from A1 to C1 levels
- **Flashcards** with flip animation and progress tracking
- **Type filter** — weak, strong, and mixed verbs
- **Level filter** — A1, A2, B1, B2, C1
- **Search** by infinitive or translation
- **Dark theme**
- **Language switch** — Russian / Ukrainian
- **Progress tracking** — mark verbs as learned, track repetitions
- **Stats** — learned verbs by level
- **Fully offline** — built-in SQLite database

## Video

- [Youtube](https://youtu.be/MbzCh3P16tI)

## Install from Release

1. Go to [Releases](https://github.com/dronov-dmitry/deutsche-verb/releases)
2. Download the archive for your platform:
   - **Windows**: `deutsche_verb-windows-x64-release.zip`
   - **Android**: `deutsche_verb-android.apk`
   - **Linux**: `deutsche_verb-linux-x64-release.zip`
3. Extract the archive (if needed) and run the executable

## Build from Source

```bash
cd client
flutter pub get
flutter build windows --release   # Windows
flutter build apk --release       # Android
flutter build linux --release     # Linux
flutter build macos --release     # macOS
flutter build ios --release       # iOS
```

## Tech Stack

- Flutter + Dart
- SQLite via sqflite_common_ffi
- Provider for state management
- url_launcher for external links

## License

Copyright (C) 2024 Dmitry Dronov

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
