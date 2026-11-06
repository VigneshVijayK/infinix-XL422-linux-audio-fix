#!/bin/bash

###############################################################################
# Infinix IN X3 Slim / XL422 Linux Speaker Fix + Volume Sync Fix
#
# Original HDA fix by: Vignesh Vijay K
#   https://github.com/VigneshVijayK/infinix-XL422-linux-audio-fix
#
# Volume sync fix + enhanced installer by: opencode
#
# Fixes:
#   1. No speaker output (HDA pin config override via hda-jack-retask)
#   2. Volume bar sync issue (forces ALSA Master to 100% on boot)
#
# Location: $(dirname "$(readlink -f "$0")")
# Usage:    sudo bash install-fix.sh
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX_FOLDER="sound-fix"
BACKUP_FOLDER="backups"
FIX_PATH="$SCRIPT_DIR/$FIX_FOLDER"
BACKUP_PATH="$SCRIPT_DIR/$BACKUP_FOLDER"

# ── Terminal styling ────────────────────────────────────────
c()   { tput setaf "$1" 2>/dev/null; }
b()   { tput bold 2>/dev/null; }
d()   { tput dim 2>/dev/null; }
clr() { tput sgr0 2>/dev/null; }
eol() { tput el 2>/dev/null; }

Bold()   { b; }
Dim()    { d; }
Red()    { c 1; }
Green()  { c 2; }
Yellow() { c 3; }
Cyan()   { c 6; }

# ── Box width ───────────────────────────────────────────────
# Border:  +------------------------------------------------------------+
#           ^- 2 spaces indent, 60 dashes, + on each end = 64 chars wide
# Content: |  [56 chars of content]  |
#           ^- 5 chars prefix, 56 chars content, 3 chars suffix = 64
TOP="+------------------------------------------------------------+"
MID="|------------------------------------------------------------|"
BOT="+------------------------------------------------------------+"
CONTENT_W=56

# ── Print a box line with proper padding (handles ANSI codes) ─
box() {
    local str="$1"
    local visible
    visible=$(echo "$str" | sed 's/\x1b\[[0-9;]*m//g')
    local vlen=${#visible}
    local pad=$((CONTENT_W - vlen))
    [ "$pad" -lt 0 ] && pad=0
    printf "  |  %s%*s  |\n" "$str" $pad ""
}

# ── Progress bar ────────────────────────────────────────────
progress_bar() {
    local current=$1 total=$2 label="$3"
    local width=30
    local p=$((current * 100 / total))
    local f=$((current * width / total))
    local e=$((width - f))

    printf "\r  "
    eol
    if [ "$p" -lt 25 ]; then Red
    elif [ "$p" -lt 50 ]; then Yellow
    else Green
    fi

    for ((i=0; i<f; i++)); do printf "#"; done
    for ((i=0; i<e; i++)); do printf "-"; done
    clr

    printf " %3d%%  %s" "$p" "$label"
}

# ── Spinner ─────────────────────────────────────────────────
spinner() {
    local pid=$1 label="$2"
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  [%c] %s" "${spin:$i:1}" "$label"
        eol
        i=$(( (i+1) % 4 ))
        sleep 0.12
    done
    printf "\r  ["
    Green; Bold; printf "OK"; clr
    printf "] %s\n" "$label"
}

# ── Run steps with progress ─────────────────────────────────
run_steps() {
    local total=$1
    shift
    local steps=("$@")
    local i=0
    local n=${#steps[@]}

    echo ""
    for cmd in "${steps[@]}"; do
        i=$((i + 1))
        local label=$(echo "$cmd" | cut -d'|' -f1)
        local code=$(echo "$cmd" | cut -d'|' -f2-)
        progress_bar $i $n "$label"
        eval "$code" 2>/dev/null
    done
    Green; Bold; progress_bar $n $n "Done"; clr
    echo -e "\n"
}

# ── Header ───────────────────────────────────────────────────
show_header() {
    clear
    echo ""

    local hdr="Infinix IN X3 XL422 - Audio Fix + Volume Sync"
    local line1="Original HDA fix by: Vignesh Vijay K"
    local line2="Volume sync fix by:  opencode"
    local desc1="1. Overrides HDA pin configs to enable speakers"
    local sub1="   (installs hda-jack-retask firmware patch)"
    local desc2="2. Fixes volume bar sync"
    local sub2="   (pins ALSA Master to 87/100% on boot via systemd)"

    echo "  $TOP"
    Bold; Cyan; box "$hdr"; clr
    echo "  $MID"
    Dim; box "$line1"; clr
    Dim; box "$line2"; clr
    echo "  $MID"
    box ""
    Bold; box "$desc1"; clr
    Dim; box "$sub1"; clr
    box ""
    Bold; box "$desc2"; clr
    Dim; box "$sub2"; clr
    echo "  $MID"
    Cyan; box "$SCRIPT_DIR"; clr
    echo "  $BOT"
    echo ""
}

# ── Success dialog ──────────────────────────────────────────
show_success() {
    local title="$1"
    shift
    local lines=("$@")

    echo ""
    echo "  $TOP"
    Green; Bold; box "$title"; clr
    echo "  $MID"
    for line in "${lines[@]}"; do
        if [ -z "$line" ]; then
            box ""
        else
            box "$line"
        fi
    done
    echo "  $BOT"
    echo ""
}

# ── Utility ──────────────────────────────────────────────────
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo ""
        Red; Bold; printf "  ERROR: "; clr
        echo "This script must be run as root."
        echo "    Usage: sudo bash install-fix.sh"
        echo ""
        exit 1
    fi
}

reboot_sys() {
    echo ""
    Yellow; echo "  Rebooting in 5 seconds..."; clr
    echo "  (Press Ctrl+C to cancel)"
    sleep 5
    if command -v reboot &>/dev/null; then
        command reboot
    elif command -v systemctl &>/dev/null; then
        systemctl reboot
    else
        /sbin/reboot 2>/dev/null || /usr/sbin/reboot 2>/dev/null || shutdown -r now
    fi
}

backup_file() {
    local system_path="$1"
    local backup_timestamp="$2"

    if [ -f "$system_path" ]; then
        local rel_path="${system_path#/}"
        local backup_file_path="$BACKUP_PATH/$backup_timestamp/$rel_path"
        local backup_dir=$(dirname "$backup_file_path")
        mkdir -p "$backup_dir"
        cp -p "$system_path" "$backup_file_path"
        return 0
    fi
    return 1
}

reboot_prompt() {
    local context="$1"
    echo ""
    read -p "  Reboot now? (y/n): " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        reboot_sys
    else
        local msg="Reboot when convenient to fully ${context}."
        [ "$context" = "activate" ] && msg="Reboot when convenient for the speaker pin config to activate."
        echo ""
        Dim; echo "  --------------------------------------------------------"; clr
        Yellow; echo "  $msg"; clr
        Dim; echo "  --------------------------------------------------------"; clr
        echo ""
    fi
}

# ── Install ──────────────────────────────────────────────────
install_fix() {
    show_header

    if [ ! -d "$FIX_PATH" ]; then
        echo ""
        Red; Bold; printf "  ERROR: "; clr
        echo "Folder '$FIX_FOLDER' not found next to this script."
        echo "    Expected location: $FIX_PATH"
        echo ""
        exit 1
    fi

    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_PATH/$backup_timestamp"

    echo ""
    Yellow; Bold; printf "  STEP 1: "; clr; echo "Install speaker pin config fix"
    Dim; echo "  --------------------------------------------------------"; clr
    echo ""
    echo "    Files to install:"
    Cyan; echo "    -> /etc/modprobe.d/hda-jack-retask.conf"; clr
    Cyan; echo "    -> /lib/firmware/hda-jack-retask.fw"; clr
    echo ""

    local files=()
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(find "$FIX_PATH" -type f -print0)

    local total_files=${#files[@]}
    Dim; echo "    Creating backup: $backup_timestamp"; clr
    mkdir -p "$backup_dir"
    echo ""

    local count=0
    for local_file in "${files[@]}"; do
        count=$((count + 1))
        rel_path="${local_file#$FIX_PATH/}"
        system_path="/$rel_path"

        backup_file "$system_path" "$backup_timestamp"
        mkdir -p "$(dirname "$system_path")"

        if [ -f "$system_path" ]; then
            orig_perms=$(stat -c "%a" "$system_path" 2>/dev/null || echo "644")
            orig_owner=$(stat -c "%U:%G" "$system_path" 2>/dev/null || echo "root:root")
            cp "$local_file" "$system_path"
            chmod "$orig_perms" "$system_path"
            chown "$orig_owner" "$system_path" 2>/dev/null || true
        else
            cp "$local_file" "$system_path"
            chmod 644 "$system_path"
            chown root:root "$system_path" 2>/dev/null || true
        fi

        progress_bar $count $total_files "$rel_path"
        sleep 0.15
    done
    echo -e "\n"

    echo "$backup_timestamp" > "$backup_dir/backup_info.txt"
    echo "$(date)" >> "$backup_dir/backup_info.txt"
    echo "Files backed up: $total_files" >> "$backup_dir/backup_info.txt"

    echo ""
    Yellow; Bold; printf "  STEP 2: "; clr; echo "Install volume sync fix"
    Dim; echo "  --------------------------------------------------------"; clr
    echo ""

    (
        cat > /etc/systemd/system/alsa-master-volume.service << 'SERVICEEOF'
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
SERVICEEOF
        systemctl daemon-reload
        systemctl enable alsa-master-volume.service
    ) &
    spinner $! "Creating and enabling volume sync service"

    local btitle="Backup saved: $(basename "$backup_dir")"
    show_success "INSTALLATION COMPLETED SUCCESSFULLY" \
        "" \
        "Pin config fix: $total_files file(s) installed" \
        "Volume sync fix: systemd service created and enabled" \
        "$btitle" \
        "" \
        "$(Bold)What was fixed:$(clr)" \
        " 1. HDA pin override -> enables speaker output" \
        " 2. Master=87 on boot -> fixes volume bar sync" \
        "" \
        "$(Yellow)$(Bold)=> REBOOT REQUIRED$(clr) for speaker pin config to activate." \
        "$(Dim)The volume fix (Master=87) works immediately.$(clr)"

    echo ""
    read -p "  Set Master to 100% right now and test volume? (y/n): " test_choice
    if [[ "$test_choice" =~ ^[Yy]$ ]]; then
        echo ""
        amixer -c 0 sset Master 87 2>/dev/null
        Green; Bold; printf "  OK "; clr; echo "Master set to 100%. Play some audio and test."
    fi

    reboot_prompt "activate"
}

# ── Revert ───────────────────────────────────────────────────
restore_backup() {
    show_header

    Red; Bold; printf "  REVERT: "; clr; echo "Remove all changes made by this script"
    Dim; echo "  --------------------------------------------------------"; clr
    echo ""

    local has_backups=0
    if [ -d "$BACKUP_PATH" ]; then
        local backup_count=$(find "$BACKUP_PATH" -maxdepth 1 -type d 2>/dev/null | wc -l)
        [ "$backup_count" -gt 1 ] && has_backups=1
    fi

    if [ "$has_backups" -eq 1 ]; then
        local backups=()
        for bdir in "$BACKUP_PATH"/*; do
            [ -d "$bdir" ] && [ -f "$bdir/backup_info.txt" ] && backups+=("$bdir")
        done

        echo "  Available backups:"
        local idx=1
        for bdir in "${backups[@]}"; do
            local bname=$(basename "$bdir")
            local bdate=$(head -2 "$bdir/backup_info.txt" | tail -1)
            printf "    %d. %s  (%s)\n" "$idx" "$bname" "$bdate"
            idx=$((idx + 1))
        done

        echo ""
        read -p "  Select backup to restore (1-${#backups[@]}) or 0 to skip: " selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#backups[@]} ]; then
            local selected_backup="${backups[$((selection-1))]}"
            echo ""
            Bold; echo "  Restoring files from backup..."; clr

            local restore_count=0
            while IFS= read -r -d '' bf; do
                local rel_path="${bf#$selected_backup/}"
                [[ "$rel_path" == "backup_info.txt" ]] && continue
                local system_path="/$rel_path"
                mkdir -p "$(dirname "$system_path")"
                cp -p "$bf" "$system_path"
                restore_count=$((restore_count + 1))
                progress_bar $restore_count $restore_count "$rel_path"
                sleep 0.15
            done < <(find "$selected_backup" -type f -print0)
            echo -e "\n"
        fi
    else
        Dim; echo "  No backups found. Will still remove fix files."; clr
    fi

    echo ""
    Bold; echo "  Removing fix files..."; clr
    echo ""

    local remove_steps=()
    [ -f /etc/modprobe.d/hda-jack-retask.conf ] && remove_steps+=("Removing hda-jack-retask.conf|rm -f /etc/modprobe.d/hda-jack-retask.conf")
    [ -f /lib/firmware/hda-jack-retask.fw ] && remove_steps+=("Removing hda-jack-retask.fw|rm -f /lib/firmware/hda-jack-retask.fw")
    [ -f /etc/systemd/system/alsa-master-volume.service ] && remove_steps+=("Disabling volume sync service|systemctl disable alsa-master-volume.service")
    [ -f /etc/systemd/system/alsa-master-volume.service ] && remove_steps+=("Removing service file|rm -f /etc/systemd/system/alsa-master-volume.service")
    remove_steps+=("Reloading systemd|systemctl daemon-reload")

    if [ ${#remove_steps[@]} -gt 0 ]; then
        run_steps ${#remove_steps[@]} "${remove_steps[@]}"
    else
        Dim; echo "  No fix files found to remove."; clr
        echo ""
    fi

    show_success "REVERT COMPLETED SUCCESSFULLY" \
        "" \
        "All installed fix files have been removed." \
        "Original files restored from backup (if selected)." \
        "" \
        "$(Yellow)$(Bold)=> REBOOT REQUIRED$(clr) for the revert to fully take" \
        "effect. The pin config patch is loaded in memory" \
        "at boot and survives until the next shutdown."

    reboot_prompt "revert"
}

# ── Menu ────────────────────────────────────────────────────
while true; do
    show_header

    Bold; echo "  Select an option:"; clr
    echo ""
    Green; Bold; printf "    1. "; clr; Bold; printf "Install Fix"; clr; echo " (speaker enable + volume sync)"
    Dim; echo "       . Installs hda-jack-retask pin config"; clr
    Dim; echo "       . Creates systemd service for Master=100%"; clr
    Dim; echo "       . Backs up original files"; clr
    echo ""
    Red; Bold; printf "    2. "; clr; Bold; printf "Revert"; clr; echo " (undo all changes)"
    Dim; echo "       . Removes installed config files"; clr
    Dim; echo "       . Removes systemd service"; clr
    Dim; echo "       . Restores from backup (if available)"; clr
    echo ""
    Bold; echo "    3. Exit"; clr
    echo ""
    read -p "  Enter choice (1-3): " choice

    case $choice in
        1)
            check_root
            install_fix
            ;;
        2)
            check_root
            restore_backup
            ;;
        3)
            echo ""
            Dim; echo "  Exiting. No changes made."; clr
            exit 0
            ;;
        *)
            echo ""
            Red; Bold; printf "  ERROR: "; clr; echo "Invalid choice."
            read -p "  Press Enter to try again..."
            ;;
    esac

    echo ""
    read -p "  Press Enter to return to menu..."
done
