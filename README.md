# LocalFlow: free, open-source voice dictation (Wispr Flow alternative)

**Hold a key, talk, let go. Your words are typed wherever your cursor is.**
LocalFlow is a free, private, open-source **voice-to-text dictation app for macOS, Windows and Linux**.
Speech recognition runs locally with OpenAI's Whisper model, so your voice never leaves your computer.

Looking for an **open-source alternative to Wispr Flow, Willow Voice, Superwhisper or Aqua Voice**? LocalFlow gives you
the same hold-to-talk workflow with no subscription, no account and no cloud audio.

- **Hold the hotkey** to talk, release to paste. **Tap it** for hands-free, tap again to finish.
  Hotkey: **Fn** on macOS, **Right Ctrl** on Windows and Linux.
- **Private and offline speech-to-text**: Whisper large-v3-turbo runs on your machine (Apple Silicon GPU, NVIDIA GPU or CPU).
- **AI cleanup** (optional, recommended) through [OpenRouter](https://openrouter.ai): removes filler words, fixes grammar,
  turns spoken lists into clean lists. Two styles: **Developer** (code in backticks, requests become clear prompts for
  AI coding tools) and **Everyday** (natural messages and emails).
- **Learns names and terms** you teach it and spells them right every time.
- Works in **any app**: Slack, email, docs, your code editor, ChatGPT and other AI chat tools.

## Why LocalFlow

| | LocalFlow | Typical paid dictation apps |
|---|---|---|
| Price | Free, open source (Apache 2.0) | Monthly subscription |
| Audio | Transcribed on your computer | Uploaded to the cloud |
| Platforms | macOS, Windows, Linux | Often macOS or Windows only |
| Account | None | Required |
| Customizable | Edit the prompt, model and hotkey | Limited |

| | macOS | Windows / Linux |
|---|---|---|
| Speech engine | MLX (Apple Silicon GPU) | faster-whisper (NVIDIA GPU if present, else CPU) |
| App | Menu-bar app + on-screen recording pill | Tray icon, settings open in your browser |
| Learns name fixes automatically | Yes | Add names by hand in Settings |

## Install

All platforms need [uv](https://docs.astral.sh/uv/getting-started/installation/). It installs Python and every dependency for you.
The first dictation downloads the speech model once (about 0.5 to 1.6 GB).

### macOS (Apple Silicon)

```sh
xcode-select --install          # once, if you don't have the command line tools
git clone https://github.com/ahmedafrid/localflow && cd localflow
./build.sh
```

This installs `/Applications/LocalFlow.app`, adds it to Login Items and opens the welcome screen.
Allow **Microphone**, **Accessibility** and **Input Monitoring**, then click *Restart LocalFlow*.

### Windows

```powershell
git clone https://github.com/ahmedafrid/localflow; cd localflow
uv run flow.py
```

The welcome page opens in your browser. To start LocalFlow at login: press `Win+R`, type `shell:startup`,
and create a shortcut there to `uv run "C:\path\to\localflow\flow.py"`.

### Linux

```sh
sudo apt install xclip           # clipboard (Fedora: dnf install xclip; Wayland: wl-clipboard)
git clone https://github.com/ahmedafrid/localflow && cd localflow
uv run flow.py
```

Hotkeys and pasting need an **X11** session (most distros offer "Xorg" at the login screen); Wayland blocks
global hotkeys. If your user can't read keyboard input, add it to the `input` group and log in again.
To start at login, add `uv run /path/to/localflow/flow.py` to your desktop's Startup Applications.

### Settings

Everything is set from the LocalFlow window (Settings button, top right). Advanced options go in the `.env` file
in your data folder, see [`.env.example`](.env.example):

- `FLOW_HOTKEY`: Windows/Linux hotkey, e.g. `ctrl_r` (default), `alt_r`, `f9`
- `FLOW_LANG`: force a language (`en`, `de`, ...); empty = auto-detect
- `FLOW_WHISPER`: a different Whisper model, e.g. `Systran/faster-whisper-small` on slower PCs

### Your install steps

Got LocalFlow running on a setup not covered above (another distro, Wayland workaround, autostart trick, Intel Mac)?
Add a short section under **Install** and open a pull request. Keep it to the commands that worked for you.

## Privacy and security

- Audio is transcribed locally and never stored.
- With an OpenRouter key, the **transcribed text** is sent to OpenRouter for cleanup. Without a key, nothing leaves your computer.
- Your key, history and names live in your data folder with owner-only permissions, never in this repo:
  macOS `~/Library/Application Support/LocalFlow`, Windows `%APPDATA%\LocalFlow`, Linux `~/.local/share/LocalFlow`.
- The settings window is served on `127.0.0.1` only, and every API call needs a random per-install token.

## Files

| File | What |
|---|---|
| `flow.py` | The whole app: hotkey, recording, Whisper, cleanup, paste, tray/menu bar, overlay, local web UI. One [uv script](https://docs.astral.sh/uv/guides/scripts/). |
| `ui.html` | The welcome, history and settings window. |
| `build.sh` | macOS only: builds a tiny signed launcher so permissions survive code edits. |

Self-check: `uv run flow.py --test`. Transcribe a file: `uv run flow.py --file clip.wav`.
Try the Windows/Linux version on a Mac: `FLOW_PORTABLE=1 uv run --with faster-whisper --with "av<17" --with pynput --with pystray --with pillow --with pyperclip flow.py`.

## Updates

LocalFlow checks `version.json` in this repo at launch and every 6 hours.
Newer version: the window shows an **Update now** banner. Older than `min`: dictation stops and the window shows only
**Update now**, until the user updates. Updating downloads the new `flow.py` and `ui.html` and restarts (a few seconds).
Offline or GitHub unreachable: nothing is blocked.

**Releasing (maintainer):**
1. Bump `VERSION` in `flow.py`.
2. In `version.json`, set `latest` to the same number and write short `notes`.
   To force everyone to update, also set `min` to it. For an optional update, leave `min` alone.
3. Push to `main`. (Changes to `build.sh` still need users to re-run `./build.sh`.)

## Contributing

Contributions are welcome, especially:

- **Mobile apps** (iOS and Android), e.g. a keyboard that uses the same cleanup prompt.
- **Bug fixes and improvements**, and testing on Windows and Linux.
- **Install steps** for setups not covered yet (see above).

Open an issue first for anything big. Keep changes small and readable, and run `uv run flow.py --test` before opening a PR.
Never commit keys or your `.env`.

## License

[Apache 2.0](LICENSE) with a [NOTICE](NOTICE). You can use, change and share LocalFlow, including commercially, as long as
you keep the NOTICE file and credit **"Based on LocalFlow by Ahmed Afrid"** with a link to this repository in your
README, credits or About screen.

## Author

Designed and built by **[Ahmed Afrid](https://github.com/ahmedafrid)**. Questions, ideas or want to work together on
something similar? [Open an issue](https://github.com/ahmedafrid/localflow/issues) or reach out through GitHub.

<sub>Wispr Flow, Willow Voice, Superwhisper and Aqua Voice are trademarks of their respective owners. LocalFlow is an
independent project and is not affiliated with them.</sub>

