# Infinix IN X3 XL422 - Linux Audio Fix + Volume Sync

Complete fix for no-speaker-output and broken volume bar sync on Infinix INBook X3 Slim (XL422) laptops running Linux.

## The Problem

This laptop has a **Realtek ALC269VB** audio codec that Linux doesn't fully initialize correctly. Two issues occur:

### 1. No Speaker Output

The kernel's `snd-hda-intel` driver misidentifies the internal speaker pin (0x14), leaving the audio routing disconnected. The speaker DAC never gets connected to the physical speaker output.

### 2. Broken Volume Bar Sync (After Fix)

Applying the HDA pin config fix causes the driver to create a virtual "Master" ALSA control that initializes at **56/87 (-23.25dB)**. Your desktop volume slider only controls PipeWire's software volume, while this hidden hardware Master sits at a fixed low value, creating **double attenuation**. Result: slider at 40% sounds like 10-20%.

## The Fix

Two changes are needed:

| Step | What | How |
|------|------|-----|
| **1** | Fix speaker routing | HDA pin config patch (`hda-jack-retask.fw`) overrides the codec's pin defaults to correctly identify the speaker output |
| **2** | Fix volume sync | Systemd service forces Master to 87/87 (0dB) on every boot, removing the hidden attenuation layer |

### How the Pin Config Works

The file `sound-fix/lib/firmware/hda-jack-retask.fw` contains:

```ini
[codec]
0x10ec0269 0x27820250 0

[pincfg]
0x14 0x90170110
```

This tells the kernel: "for Realtek ALC269VB (vendor 0x10EC, subsystem 0x2782), override pin 0x14 as a fixed internal speaker with analog connection." Without this, the driver leaves the pin unconfigured and no audio reaches the speakers.

### How the Volume Sync Works

The pin config override triggers the HDA generic parser to create a "Master" virtual control alongside the individual "Speaker Playback Volume" control. This Master initializes at 56/87 in hardware. The systemd service:

```bash
amixer -c 0 sset Master 87
```

runs 3 seconds after boot to pin it to maximum (0dB), making it transparent. Only PipeWire's software volume then controls loudness.

## Installation

### One-liner (curl)

```bash
curl -sSL https://raw.githubusercontent.com/VigneshVijayK/infinix-XL422-linux-audio-fix/main/sound-fix/lib/firmware/hda-jack-retask.fw -o /tmp/hda-jack-retask.fw
curl -sSL https://raw.githubusercontent.com/VigneshVijayK/infinix-XL422-linux-audio-fix/main/sound-fix/etc/modprobe.d/hda-jack-retask.conf -o /tmp/hda-jack-retask.conf
sudo cp /tmp/hda-jack-retask.fw /lib/firmware/
sudo cp /tmp/hda-jack-retask.conf /etc/modprobe.d/
sudo bash -c 'cat > /etc/systemd/system/alsa-master-volume.service << EOF
[Unit]
Description=Set ALSA Master volume to 100% (fix volume sync)
After=alsa-restore.service sound.target
Requires=alsa-restore.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/amixer -c 0 sset Master 87
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl daemon-reload
sudo systemctl enable alsa-master-volume.service
echo "Done. Reboot required."
```

### Using the script (recommended)

```bash
git clone https://github.com/VigneshVijayK/infinix-XL422-linux-audio-fix.git
cd infinix-XL422-linux-audio-fix
sudo bash install-fix.sh
```

The script shows an interactive menu: choose **1** to install, **2** to revert.

### What the Script Does

1. Backs up original `/etc/modprobe.d/hda-jack-retask.conf` and `/lib/firmware/hda-jack-retask.fw` (if they exist)
2. Copies the fixed versions from `sound-fix/` to the system
3. Creates and enables `alsa-master-volume.service`
4. Offers to set Master=87 immediately for testing
5. Prompts for reboot

### Options

- **Install** (option 1): Applies the speaker fix + volume sync fix
- **Revert** (option 2): Removes all installed files, disables the service, restores originals from backup

### Revert

```bash
sudo bash install-fix.sh
# Select option 2
```

## Project Structure

```
infinix-XL422-linux-audio-fix/
├── install-fix.sh                   # Main installer script
├── README.md                        # This file
├── LICENSE                          # MIT License
└── sound-fix/
    ├── etc/
    │   └── modprobe.d/
    │       └── hda-jack-retask.conf # Kernel module options
    └── lib/
        └── firmware/
            └── hda-jack-retask.fw   # Pin config override

backups/                             # Created automatically by the script (not tracked)
```

## Credits

- **Vignesh Vijay K** -- Original HDA pin config fix
  - GitHub: [@VigneshVijayK](https://github.com/VigneshVijayK)
  - Repository: https://github.com/VigneshVijayK/infinix-XL422-linux-audio-fix
- **opencode** -- Volume sync fix (Master=100% on boot), enhanced installer

## Tested On

| Component | Version |
|-----------|---------|
| Laptop | Infinix INBook X3 Slim (XL422) |
| Audio Codec | Realtek ALC269VB |
| Kernel | Linux 6.14.0-37-generic |
| Distro | Ubuntu 24.04.3 LTS |
| Audio Server | PipeWire 1.4.2 + WirePlumber |

## License

MIT
