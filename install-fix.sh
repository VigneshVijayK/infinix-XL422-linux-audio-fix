#!/bin/bash

###############################################################################
# Infinix IN X3 Slim Linux Speaker Fix
# 
# This script replaces system audio configuration files to fix speaker issues
# on Infinix IN X3 Slim laptops running Linux.
#
# Author: Vignesh Vijay K
# GitHub: https://github.com/VigneshVijayK
# 
# Usage: sudo bash install-fix.sh
###############################################################################

FIX_FOLDER="sound-fix"
BACKUP_FOLDER="backups"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    echo "Usage: sudo bash install-fix.sh"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX_PATH="$SCRIPT_DIR/$FIX_FOLDER"
BACKUP_PATH="$SCRIPT_DIR/$BACKUP_FOLDER"

# Function to backup a file
backup_file() {
    local system_path="$1"
    local backup_timestamp="$2"
    
    if [ -f "$system_path" ]; then
        local rel_path="${system_path#/}"
        local backup_file_path="$BACKUP_PATH/$backup_timestamp/$rel_path"
        local backup_dir=$(dirname "$backup_file_path")
        
        mkdir -p "$backup_dir"
        cp -p "$system_path" "$backup_file_path"
        echo "  Backed up: $system_path"
        return 0
    fi
    return 1
}

# Function to install fix
install_fix() {
    if [ ! -d "$FIX_FOLDER" ]; then
        echo "Error: Folder '$FIX_FOLDER' not found!"
        echo "Please create a folder named '$FIX_FOLDER' with your fix files."
        return 1
    fi
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_PATH/$backup_timestamp"
    
    echo "=========================================="
    echo "Installing Speaker Fix"
    echo "=========================================="
    echo ""
    echo "Creating backup: $backup_timestamp"
    mkdir -p "$backup_dir"
    echo ""
    
    # Find all files in fix folder and replace them
    find "$FIX_PATH" -type f | while read -r local_file; do
        # Get relative path from fix folder
        rel_path="${local_file#$FIX_PATH/}"
        # System path (same structure)
        system_path="/$rel_path"
        
        # Backup existing file
        backup_file "$system_path" "$backup_timestamp"
        
        # Create directory if needed
        mkdir -p "$(dirname "$system_path")"
        
        # Copy file preserving permissions from original if it exists
        if [ -f "$system_path" ]; then
            # Get original permissions and ownership
            local orig_perms=$(stat -c "%a" "$system_path" 2>/dev/null || echo "644")
            local orig_owner=$(stat -c "%U:%G" "$system_path" 2>/dev/null || echo "root:root")
            
            cp "$local_file" "$system_path"
            chmod "$orig_perms" "$system_path"
            chown "$orig_owner" "$system_path" 2>/dev/null || true
        else
            # New file, use default permissions
            cp "$local_file" "$system_path"
            chmod 644 "$system_path"
            chown root:root "$system_path" 2>/dev/null || true
        fi
        
        echo "  Replaced: $system_path"
    done
    
    # Count files
    local file_count=$(find "$FIX_PATH" -type f | wc -l)
    
    # Save backup info
    echo "$backup_timestamp" > "$backup_dir/backup_info.txt"
    echo "$(date)" >> "$backup_dir/backup_info.txt"
    echo "Files backed up: $file_count" >> "$backup_dir/backup_info.txt"
    
    echo ""
    echo "=========================================="
    echo "Installation complete!"
    echo "=========================================="
    echo "Files replaced: $file_count"
    echo "Backup saved to: $backup_dir"
    echo ""
    
    # Ask to restart system
    echo ""
    read -p "Do you want to restart the system now? (y/n): " restart_choice
    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Restarting system in 5 seconds... (Press Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        echo ""
        echo "Please restart your system manually for changes to take effect."
        echo "You can restart later with: sudo reboot"
    fi
}

# Function to restore from backup
restore_backup() {
    if [ ! -d "$BACKUP_PATH" ]; then
        echo "Error: No backups found!"
        return 1
    fi
    
    # List available backups
    echo "=========================================="
    echo "Available Backups"
    echo "=========================================="
    echo ""
    
    local backups=()
    local index=1
    
    for backup_dir in "$BACKUP_PATH"/*; do
        if [ -d "$backup_dir" ] && [ -f "$backup_dir/backup_info.txt" ]; then
            local backup_name=$(basename "$backup_dir")
            local backup_date=$(head -2 "$backup_dir/backup_info.txt" | tail -1)
            backups+=("$backup_dir")
            echo "$index. $backup_name ($backup_date)"
            ((index++))
        fi
    done
    
    if [ ${#backups[@]} -eq 0 ]; then
        echo "No backups found!"
        return 1
    fi
    
    echo ""
    read -p "Select backup to restore (1-${#backups[@]}): " selection
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
        echo "Invalid selection!"
        return 1
    fi
    
    local selected_backup="${backups[$((selection-1))]}"
    local backup_name=$(basename "$selected_backup")
    
    echo ""
    echo "=========================================="
    echo "Restoring from backup: $backup_name"
    echo "=========================================="
    echo ""
    
    # Restore all files from backup
    find "$selected_backup" -type f ! -name "backup_info.txt" | while read -r backup_file; do
        local rel_path="${backup_file#$selected_backup/}"
        local system_path="/$rel_path"
        
        if [ -f "$backup_file" ]; then
            # Create directory if needed
            mkdir -p "$(dirname "$system_path")"
            
            # Restore file with original permissions
            cp -p "$backup_file" "$system_path"
            echo "  Restored: $system_path"
        fi
    done
    
    local restore_count=$(find "$selected_backup" -type f ! -name "backup_info.txt" | wc -l)
    
    echo ""
    echo "=========================================="
    echo "Restore complete!"
    echo "=========================================="
    echo "Files restored: $restore_count"
    echo ""
    
    # Ask to restart system
    echo ""
    read -p "Do you want to restart the system now? (y/n): " restart_choice
    if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Restarting system in 5 seconds... (Press Ctrl+C to cancel)"
        sleep 5
        reboot
    else
        echo ""
        echo "Please restart your system manually for changes to take effect."
        echo "You can restart later with: sudo reboot"
    fi
}

# Main menu
while true; do
    echo ""
    echo "=========================================="
    echo ""
    echo "  Infinix IN X3 Slim / XL422 Speaker Fix"
    echo ""
    echo "            by Vignesh Vijay K"
    echo ""
    echo "     https://github.com/VigneshVijayK"
    echo ""
    echo "=========================================="
    echo ""
    echo "1. Install Fix (with backup)"
    echo "2. Restore from Backup"
    echo "3. Exit"
    echo ""
    read -p "Select an option (1-3): " choice
    
    case $choice in
        1)
            install_fix
            ;;
        2)
            restore_backup
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option! Please select 1, 2, or 3."
            ;;
    esac
done
