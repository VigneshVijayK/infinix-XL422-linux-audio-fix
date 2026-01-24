# Infinix IN X3 Slim Linux Speaker Fix

A fix for speaker issues on Infinix IN X3 Slim laptops running Linux. This solution replaces specific audio configuration files to enable speaker functionality.

## 📋 Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Prerequisites](#prerequisites)
- [How to Run](#how-to-run)
- [Installation](#installation)
- [Verification](#verification)
- [Restoring Original Files](#restoring-original-files)
- [Troubleshooting](#troubleshooting)
- [System Information](#system-information)
- [File Structure](#file-structure)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)

## Problem

After switching to Linux on the Infinix IN X3 Slim laptop, the speakers were not working. No existing solutions were found online, so this fix was developed to resolve the issue.

## Solution

This fix replaces specific audio configuration files (`hda-jack-retask.conf` and `hda-jack-retask.fw`) to enable speaker functionality on Infinix IN X3 Slim laptops running Linux.

## Prerequisites

- **Laptop Model**: Infinix IN X3 Slim
- **Linux Distribution**: Ubuntu 24.04.3 LTS (tested)
- **Kernel Version**: Linux 6.14.0-37-generic (tested)
- **Root/sudo access** (required to replace system files)
- **Backup of your system** (recommended, though the script creates automatic backups)

## How to Run

### Method 1: Using bash (Recommended)

1. **Open a terminal** in the directory containing the script

2. **Make the script executable** (optional but recommended):
   ```bash
   chmod +x install-fix.sh
   ```

3. **Run the script with sudo**:
   ```bash
   sudo bash install-fix.sh
   ```
   
   Or if you made it executable:
   ```bash
   sudo ./install-fix.sh
   ```

### Method 2: Direct Execution

If the script is already executable, you can run it directly:
```bash
sudo ./install-fix.sh
```

### What to Expect

When you run the script, you'll see an interactive menu:

```
==========================================
Infinix IN X3 Slim Speaker Fix
==========================================

1. Install Fix (with backup)
2. Restore from Backup
3. Exit

Select an option (1-3):
```

**To install the fix:**
1. Type `1` and press Enter
2. The script will create a backup and replace system files
3. You'll be asked if you want to restart the system (type `y` for yes or `n` for no)

**To restore from backup:**
1. Type `2` and press Enter
2. You'll see a list of available backups with timestamps
3. Select the backup number you want to restore
4. You'll be asked if you want to restart the system

**To exit:**
- Type `3` and press Enter

### Important Notes

- **You must run the script with `sudo`** - it needs root privileges to replace system files
- **The `sound-fix` folder must be in the same directory** as the script
- **All original files are automatically backed up** before replacement
- **You may need to restart your system** for changes to take effect

### Example Session

```bash
$ sudo bash install-fix.sh

==========================================
Infinix IN X3 Slim Speaker Fix
==========================================

1. Install Fix (with backup)
2. Restore from Backup
3. Exit

Select an option (1-3): 1

==========================================
Installing Speaker Fix
==========================================

Creating backup: 20241215_143022

  Backed up: /etc/modprobe.d/hda-jack-retask.conf
  Replaced: /etc/modprobe.d/hda-jack-retask.conf
  Backed up: /lib/firmware/hda-jack-retask.fw
  Replaced: /lib/firmware/hda-jack-retask.fw

==========================================
Installation complete!
==========================================
Files replaced: 2
Backup saved to: /path/to/backups/20241215_143022

Do you want to restart the system now? (y/n): y
Restarting system in 5 seconds... (Press Ctrl+C to cancel)
```

## Installation

### Quick Start

1. **Clone or download this repository**

2. **Ensure the `sound-fix` folder exists** with your fix files, maintaining the same directory structure as the system:
   ```
   sound-fix/
   ├── etc/
   │   └── modprobe.d/
   │       └── hda-jack-retask.conf
   └── lib/
       └── firmware/
           └── hda-jack-retask.fw
   ```

3. **Run the installation script**:
   ```bash
   sudo bash install-fix.sh
   ```

4. **Select option 1** from the menu to install the fix

### Installation Process

The script provides an interactive menu with the following options:

#### Option 1: Install Fix (with backup)
- Automatically creates a timestamped backup of all original system files
- Replaces system files with fixed versions from the `sound-fix` folder
- Preserves original file permissions and ownership
- Prompts to restart the system after installation

#### Option 2: Restore from Backup
- Lists all available backups with timestamps
- Allows you to select and restore from any previous backup
- Restores files with original permissions
- Prompts to restart the system after restoration

#### Option 3: Exit
- Exits the script

### What the Script Does

- **Automatic Backups**: All original files are backed up to `backups/TIMESTAMP/` before replacement
- **Permission Preservation**: Original file permissions and ownership are maintained
- **Safe Restoration**: Easy restore process if anything goes wrong
- **System Restart**: Optional system restart after installation/restoration

## Verification

After applying the fix, verify that speakers are working:

```bash
# Test audio output
speaker-test -t wav -c 2
```

Or play a test audio file:
```bash
aplay /usr/share/sounds/alsa/Front_Left.wav
```

You can also test with any media player or system sounds.

## Restoring Original Files

If you need to restore the original system files:

1. Run the script: `sudo bash install-fix.sh`
2. Select option **2** (Restore from Backup)
3. Choose the backup you want to restore from
4. Confirm the restoration
5. Restart your system when prompted

All backups are stored in the `backups/` folder with timestamps for easy identification.

## Troubleshooting

### Issue: Script says "sound-fix folder not found"
- Make sure the folder is named exactly `sound-fix` (with a hyphen, not a space)
- Ensure the folder is in the same directory as the installation script

### Issue: Fix doesn't work after installation
- Try restarting your system (the script should prompt you, but you can do it manually)
- Check if audio services are running: `systemctl --user status pulseaudio` or `systemctl --user status pipewire`
- Verify files were replaced: Check if the files in `sound-fix` match what's in the system

### Issue: Audio still not working
- Restore from backup and try again
- Check your audio settings in system preferences
- Verify your audio device is selected correctly
- Check system logs: `dmesg | grep -i audio` or `journalctl -u pulseaudio`

### Issue: Need to restore but forgot which backup
- All backups are in the `backups/` folder
- Each backup folder contains a `backup_info.txt` file with timestamp and file count
- The restore menu shows backup dates to help you choose

### Issue: Permission denied errors
- Make sure you're running the script with `sudo`
- Check that you have root/sudo privileges: `sudo -v`

## System Information

- **Supported Laptop Model**: Infinix IN X3 Slim
- **Tested Linux Distributions**: Ubuntu 24.04.3 LTS
- **Tested Kernel Version**: Linux 6.14.0-37-generic
- **Audio System**: ALSA with HDA Jack Retask firmware

## File Structure

The fix includes:
- `/etc/modprobe.d/hda-jack-retask.conf` - Audio module configuration
- `/lib/firmware/hda-jack-retask.fw` - Audio firmware file

## Contributing

If you have improvements or encounter issues, please:
1. Open an issue describing the problem or enhancement
2. Submit a pull request with your fix
3. Test on your Infinix IN X3 Slim before submitting

## License

MIT License - See [LICENSE](LICENSE) file for details

## Credits

Developed by [Vignesh Vijay K](https://github.com/VigneshVijayK) after encountering and solving the speaker issue on Infinix IN X3 Slim laptops. This fix replaces specific audio configuration files to enable speaker functionality.

**GitHub**: [@VigneshVijayK](https://github.com/VigneshVijayK)

## Disclaimer

This fix is provided as-is. Use at your own risk. The script creates automatic backups, but it's always recommended to have a full system backup before making system-level changes. The authors are not responsible for any damage to your system.
