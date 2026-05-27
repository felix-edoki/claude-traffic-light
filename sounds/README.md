# sounds/

Drop ElevenLabs-generated WAV files here. Expected filenames:

- `ready.wav`   — 🟢 idle, ready for prompt
- `working.wav` — 🟡 Claude is working
- `waiting.wav` — 🔴 needs your input

Missing files fail silently. Override the directory with `TRAFFIC_LIGHT_SOUNDS=/path/to/dir`.
