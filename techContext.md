# Tech Context

## Languages / Frameworks
- Flutter (Dart)
- FastAPI (Python)
- Kotlin for Android platform layer
- ffmpeg and yt-dlp for backend work

## Dependencies
- yt-dlp
- ffmpeg
- uv (Python package manager)
- Flutter plugins: receive_sharing_intent, path_provider

## Local Development Setup
- Flutter Android SDK installed
- Backend runs via `uv run python main.py`
- Build APK via `flutter build apk --release`

## Constraints
- Must comply with Play Store policies (no YouTube)
- Local-only API usage for security/privacy
- Low RAM and CPU usage on mobile
