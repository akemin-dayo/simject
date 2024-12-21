#!/bin/bash

# EXPERIMENTAL script
# Based on https://github.com/EthanArbuckle/Tmpfs-Overlay

# This tool needs to be run with sudo. It may need to be given Full Disk Access or Developer Tools permissions.

# Function to mount tmpfs to the target directory
mount_tmpfs_to_target_dir() {
    local target_dir_path="$1"
    if sudo mount_tmpfs "$target_dir_path"; then
        return 0  # success
    else
        echo "An error occurred while mounting tmpfs onto $target_dir_path"
        return 1
    fi
}

# Function to check if tmpfs is mounted on the target directory
tmpfs_mounted_on_directory() {
    local target_dir_path="$1"
    mount_output=$(mount)
    if echo "$mount_output" | grep -q "tmpfs on $target_dir_path"; then
        return 0
    else
        return 1
    fi
}

# Function to set up an overlay on the target directory
setup_overlay_on_directory() {
    local target_dir_path="$1"
    
    if [ ! -d "$target_dir_path" ]; then
        echo "Cannot set up overlay on non-existent directory: $target_dir_path"
        return 1
    fi

    if tmpfs_mounted_on_directory "$target_dir_path"; then
        echo "tmpfs is already mounted on $target_dir_path"
        return 0  # success (no need to mount again)
    fi

    # Create a temporary directory to copy contents to
    temp_dir=$(mktemp -d -p /tmp)
    if [ ! -d "$temp_dir" ]; then
        echo "Failed to create temporary directory"
        return 1
    fi
    echo "Created temporary directory: $temp_dir"

    # Copy contents of the target directory to the temporary directory
    echo "Copying contents of $target_dir_path to temporary directory"
    rsync -a "$target_dir_path"/ "$temp_dir"/

    # Create a tmpfs mount at the target directory
    if ! mount_tmpfs_to_target_dir "$target_dir_path"; then
        return 1
    fi

    # Move the contents of the temporary directory back to the tmpfs mount
    echo "Moving contents back to $target_dir_path"
    sudo rsync -a --exclude='*fsevent*' "$temp_dir"/ "$target_dir_path"/

    # Clean up the temporary directory
    rm -rf "$temp_dir"

    return 0
}

# Main script execution
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

input_path="$1"

if [ ! -d "$input_path" ]; then
    echo "Error: $input_path does not exist"
    exit 1
fi

if ! setup_overlay_on_directory "$input_path"; then
    echo "Failed to set up overlay on directory $input_path"
    exit 1
fi

echo "Successfully set up overlay on directory $input_path"
