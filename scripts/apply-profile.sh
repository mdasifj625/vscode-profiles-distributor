#!/bin/bash

# This script applies the selected VS Code profile to the user's setup.

PROFILE_DIR="./profiles"
DEFAULT_PROFILE="Default.code-profile"

# Function to apply a profile
apply_profile() {
    local profile_name=$1
    local profile_path="$PROFILE_DIR/$profile_name"

    if [ -f "$profile_path" ]; then
        echo "Applying profile: $profile_name"
        # Copy the profile settings to the user's VS Code settings directory
        cp "$profile_path" "$HOME/.config/Code/User/settings.json"
        echo "Profile $profile_name applied successfully."
    else
        echo "Profile $profile_name does not exist."
    fi
}

# Apply the default profile first
apply_profile "$DEFAULT_PROFILE"

# Check for additional profiles to apply
if [ "$#" -gt 0 ]; then
    for profile in "$@"; do
        apply_profile "$profile"
    done
else
    echo "No additional profiles specified. Only the default profile has been applied."
fi