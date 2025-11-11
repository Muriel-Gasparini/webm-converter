# WebM Converter

Automated WebM to MP4 conversion daemon optimized for Gnome ScreenCast recordings.

## Installation

### Automated Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/master/install.sh | bash
```

The installer performs the following operations:
- Installs FFmpeg via apt package manager if not present
- Downloads pre-compiled v1.0.0 binary release
- Deploys executable to `~/.local/bin`
- Configures PATH environment variable
- Creates monitoring directory `~/Videos/Screencasts`
- Optionally configures systemd service unit

### Uninstallation

```bash
curl -fsSL https://raw.githubusercontent.com/Muriel-Gasparini/webm-converter/master/uninstall.sh | bash
```

Removal operations:
- Stops and removes systemd service unit
- Removes binary from `~/.local/bin`
- Optional FFmpeg removal
- Optional orphaned package cleanup

## Architecture

### Core Components

- **File System Monitor**: Detects WebM file creation events using `fs.watch`
- **Recording Completion Detector**: Validates file stability via size monitoring and `lsof` process checking
- **Transcoder**: Spawns FFmpeg child processes with H.264/AAC codec configuration
- **Notification System**: Desktop notifications via `node-notifier`

### Workflow

1. Gnome ScreenCast recording initiated (Ctrl+Alt+Shift+R)
2. File system watcher detects `.webm` creation in `~/Videos/Screencasts`
3. Stability verification: file size monitoring (3s intervals) + `lsof` lock detection
4. Transcoding triggered after 5s grace period
5. Real-time progress tracking via FFmpeg stderr parsing
6. Desktop notification on completion/failure

## Technical Specifications

### Video Encoding Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Video Codec | libx264 | H.264 baseline compatibility |
| Audio Codec | AAC | Universal playback support |
| Profile | main | Balance between quality and compatibility |
| Pixel Format | yuv420p | Maximum decoder compatibility |
| CRF | 23 | Perceptually lossless compression |
| Preset | veryfast | Real-time encoding optimization |
| Scaling | 1280px width | Standardized HD resolution |
| Frame Rate | 30 fps | Screen recording standard |

### System Requirements

- Linux distribution with systemd init system
- FFmpeg (installed automatically via apt)
- curl or wget for remote installation
- Node.js runtime (bundled in standalone binary)

## Usage

### Standalone Execution

```bash
webm-converter
```

Initiates foreground monitoring process. Terminate with Ctrl+C.

### Systemd Service Management

```bash
# Service status inspection
systemctl status webm-converter

# Service lifecycle control
systemctl stop webm-converter
systemctl start webm-converter
systemctl restart webm-converter

# Real-time log streaming
journalctl -u webm-converter -f
```

## Configuration

### Environment Variables

```bash
export WEBM_WATCH_DIR="/custom/path"
webm-converter
```

Default monitoring directory: `~/Videos/Screencasts`

### Encoding Customization

Modify FFmpeg parameters in `index.js:129-152` and rebuild:

```bash
git clone https://github.com/Muriel-Gasparini/webm-converter.git
cd webm-converter
yarn install
yarn build:linux
```

## Deployment

### Local Service Installation

```bash
sudo ./install-service.sh
```

Generates customized systemd unit file with user-specific paths and environment configuration.

## Project Structure

```
webm-converter/
├── index.js                    # Core application logic
├── package.json                # Node.js dependencies and pkg configuration
├── webm-converter.service      # Systemd unit template
├── install.sh                  # Remote installation orchestrator
├── uninstall.sh                # Removal and cleanup automation
├── install-service.sh          # Local systemd service configurator
├── uninstall-service.sh        # Service removal utility
└── dist/                       # Compiled binary artifacts (~46MB)
```

## Troubleshooting

### Service Initialization Failure

```bash
journalctl -u webm-converter --since "1 hour ago"
webm-converter  # Manual execution for diagnostics
ffmpeg -version  # Dependency verification
```

### FFmpeg Not Found

```bash
sudo apt update && sudo apt install ffmpeg
which ffmpeg
```

### Directory Monitoring Issues

```bash
ls -la ~/Videos/Screencasts
mkdir -p ~/Videos/Screencasts
```

## Implementation Details

### v1.0.0 Architecture

- **FFmpeg Integration**: System-level FFmpeg via apt package manager
- **Binary Distribution**: Self-contained executable via pkg bundler
- **Process Spawning**: Native `child_process.spawn` for maximum performance
- **Deployment**: Direct binary download from GitHub releases

### Performance Characteristics

- **File Detection Latency**: <100ms (fs.watch event-driven)
- **Stability Verification**: 3s polling interval + 5s grace period
- **Memory Footprint**: ~50MB resident (Node.js runtime + application)
- **CPU Overhead**: Minimal (event-driven architecture, no polling except during verification)

## License

MIT License - See LICENSE file for complete terms.

## Repository

https://github.com/Muriel-Gasparini/webm-converter
