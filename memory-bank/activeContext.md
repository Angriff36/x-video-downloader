# Active Context

## Current Focus

Stabilizing the mobile Android build of the X Video Downloader app. Adding support for additional platforms (Twitch, Reddit, etc.), debugging Rumble issues, and improving storage handling.

## Recent Changes

- Added Kotlin permission handling
- Integrated ffmpeg backend via FastAPI
- Added MANAGE_EXTERNAL_STORAGE permission
- Confirmed Rumble and Twitter work; Vimeo fails

## Next Steps

- Add fallback UI for unsupported sites
- Improve user error feedback
- Create desktop build pipeline
- Handle albums/media groups in backend

## Design/Code Patterns Observed

- Local Python API with yt-dlp and ffmpeg
- Flutter frontend separated by platform
- Kotlin-based Android integration

## Learnings

- yt-dlp config must be tuned per-site
- Rumble returns false positives but works
