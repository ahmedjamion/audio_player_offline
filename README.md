# Audio Player Offline

Offline music player built with Flutter, focused on Android-first local playback.

## Tech Stack

- State: `provider`
- Storage: `hive` + `shared_preferences`
- Playback: `just_audio` + `just_audio_background`
- Metadata and scanning: `audio_metadata_reader`, `media_store_plus`

## Quality Gates

- `flutter analyze` must pass
- `flutter test` must pass
- GitHub Actions CI runs analyze + test on push/PR

## Security/Privacy Notes

- Android uses modern read permissions (`READ_MEDIA_AUDIO` for Android 13+, `READ_EXTERNAL_STORAGE` for older versions)
- iOS requests media library access for playback only
- No microphone permission is requested

## Future Migration Note

Current data layer stays on `Hive v2` for stability and simplicity. If future requirements need stronger querying or larger-scale local data operations, evaluate a planned migration to Isar or Hive CE in a separate milestone.

## Credits

- opencode (AI coding assistant) for rules implementation, routing, theme styling, and feature enhancements.
- Codex (GPT-5, OpenAI) for implementation and modernization support.
- Google Antigravity (Gemini) for earlier development assistance.
- GitHub Copilot for earlier development assistance.

