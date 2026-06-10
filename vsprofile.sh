#!/bin/bash

# VS Code Profiles Distributor - Pure Bash Implementation
# Requirements: jq (Command-line JSON processor)

# Color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}Welcome to VS Code Profiles Distributor!${NC}"

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: 'jq' is not installed. It is required for JSON processing.${NC}"
    if command -v apt-get &> /dev/null; then
        echo -e "${CYAN}Attempting to install 'jq' automatically via apt-get...${NC}"
        sudo apt-get update && sudo apt-get install -y jq
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install 'jq'. Please install it manually.${NC}"
            exit 1
        fi
        echo -e "${GREEN}'jq' installed successfully!${NC}"
    else
        echo -e "${RED}Error: 'jq' is missing and cannot be installed automatically on this OS. Please install it manually.${NC}"
        echo "Mac: brew install jq"
        echo "Windows (Git Bash): winget install jqlang.jq"
        exit 1
    fi
fi

PROFILES_DIR="$(pwd)/profiles"
if [ ! -d "$PROFILES_DIR" ]; then
    echo -e "${RED}Error: Profiles directory not found at $PROFILES_DIR${NC}"
    exit 1
fi

# Detect OS and set User Data Path
IS_WSL=false
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    IS_WSL=true
fi

if [ "$IS_WSL" = true ]; then
    WIN_APPDATA=$(cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')
    if command -v wslpath &> /dev/null; then
        USER_DATA_PATH="$(wslpath "$WIN_APPDATA")/Code/User"
    else
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        USER_DATA_PATH="/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User"
    fi
    echo -e "${YELLOW}Detected WSL environment. Targeting Windows Settings at: $USER_DATA_PATH${NC}"
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ] || [ "$(expr substr $(uname -s) 1 4)" == "MSYS" ]; then
    # Git Bash on Windows
    USER_DATA_PATH="$APPDATA/Code/User"
elif [ "$(uname)" == "Darwin" ]; then
    # Mac
    USER_DATA_PATH="$HOME/Library/Application Support/Code/User"
else
    # Native Linux
    USER_DATA_PATH="$HOME/.config/Code/User"
fi

SETTINGS_PATH="$USER_DATA_PATH/settings.json"
KEYBINDINGS_PATH="$USER_DATA_PATH/keybindings.json"

# Create directories if they don't exist
mkdir -p "$USER_DATA_PATH"
[ ! -f "$SETTINGS_PATH" ] && echo "{}" > "$SETTINGS_PATH"
[ ! -f "$KEYBINDINGS_PATH" ] && echo "[]" > "$KEYBINDINGS_PATH"

# Function to get extensions from a profile safely
get_profile_extensions() {
    local profile_file=$1
    jq -r '
        if .extensions == null then empty
        elif (.extensions | type) == "array" then .extensions[]
        elif (.extensions | type) == "object" and (.extensions.extensions | type) == "array" then
            .extensions.extensions[] | if type=="object" then .id else . end
        else empty
        end
    ' "$profile_file"
}

# Function to extract only settings from a profile
get_profile_settings() {
    local profile_file=$1
    jq '.settings // {}' "$profile_file"
}

# Function to extract only keybindings from a profile
get_profile_keybindings() {
    local profile_file=$1
    jq '.keybindings // []' "$profile_file"
}

apply_profile() {
    local profile_name=$1
    local mode=$2
    local profile_file="$PROFILES_DIR/$profile_name.code-profile"
    local default_file="$PROFILES_DIR/Default.code-profile"

    echo -e "\n${CYAN}Applying Profile: $profile_name in $mode mode...${NC}"

    # Prepare merged profile data (Inherit from Default if not applying Default itself)
    local merged_profile=$(mktemp)
    if [ "$profile_name" != "Default" ] && [ -f "$default_file" ]; then
        echo -e "${YELLOW}Merging with Default profile...${NC}"
        jq -s '
            def get_exts:
                if . == null then []
                elif type == "array" then .
                elif type == "object" and (.extensions | type) == "array" then [.extensions[] | if type=="object" then .id else . end]
                else [] end;

            (.[0] // {}) * (.[1] // {})
            | .settings = ((.[0].settings // {}) * (.[1].settings // {}))
            | .extensions = ((.[0].extensions | get_exts) + (.[1].extensions | get_exts) | unique)
            | .keybindings = ((.[0].keybindings // []) + (.[1].keybindings // []) | unique)
        ' "$default_file" "$profile_file" > "$merged_profile"
    else
        cat "$profile_file" > "$merged_profile"
    fi

    if [ "$mode" == "replace" ]; then
        echo -e "${YELLOW}Uninstalling all current extensions...${NC}"
        code --list-extensions | while read -r ext; do
            if [ -n "$ext" ]; then
                echo "Uninstalling: $ext"
                code --uninstall-extension "$ext" --force >/dev/null 2>&1
            fi
        done

        get_profile_settings "$merged_profile" > "$SETTINGS_PATH"
        get_profile_keybindings "$merged_profile" > "$KEYBINDINGS_PATH"
        echo -e "${GREEN}Settings and Keybindings replaced.${NC}"
        
    elif [ "$mode" == "sync" ]; then
        # Merge settings (Deep Merge)
        local temp_settings=$(mktemp)
        # Ensure current settings is valid JSON
        [ ! -s "$SETTINGS_PATH" ] && echo "{}" > "$SETTINGS_PATH"
        jq -s '(.[0] // {}) * (.[1] // {})' "$SETTINGS_PATH" <(get_profile_settings "$merged_profile") > "$temp_settings"
        mv "$temp_settings" "$SETTINGS_PATH"
        
        # Merge keybindings (Array Concat & Unique)
        local temp_keybindings=$(mktemp)
        [ ! -s "$KEYBINDINGS_PATH" ] && echo "[]" > "$KEYBINDINGS_PATH"
        jq -s '((.[0] // []) + (.[1] // [])) | unique' "$KEYBINDINGS_PATH" <(get_profile_keybindings "$merged_profile") > "$temp_keybindings"
        mv "$temp_keybindings" "$KEYBINDINGS_PATH"
        
        echo -e "${GREEN}Settings and Keybindings merged safely.${NC}"
    fi

    # Install extensions
    echo -e "${YELLOW}Installing extensions...${NC}"
    get_profile_extensions "$merged_profile" | while read -r ext; do
        if [ -n "$ext" ]; then
            echo "Installing: $ext"
            code --install-extension "$ext" --force >/dev/null 2>&1
        fi
    done

    rm "$merged_profile"
    echo -e "${GREEN}Profile '$profile_name' successfully applied!${NC}\n"
}

# Arrow Key Menu Function
arrow_menu() {
    local prompt="$1" outvar="$2"
    shift 2
    local options=("$@")
    local cur=0
    local count=${#options[@]}
    local key

    tput civis # hide cursor
    echo -e "${CYAN}$prompt${NC}"
    
    # Save cursor position
    tput sc

    while true; do
        tput rc # restore cursor position
        for ((i=0; i<count; i++)); do
            # clear line
            echo -en "\e[2K\r"
            if [ "$i" -eq "$cur" ]; then
                echo -e "  ${GREEN}❯ ${options[$i]}${NC}"
            else
                echo -e "    ${options[$i]}"
            fi
        done
        
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key == "[A" ]]; then # Up
                ((cur--))
                ((cur < 0)) && cur=$((count - 1))
            elif [[ $key == "[B" ]]; then # Down
                ((cur++))
                ((cur >= count)) && cur=0
            fi
        elif [[ $key == "" ]]; then # Enter
            break
        fi
    done
    tput cnorm # restore cursor
    eval $outvar="${cur}"
}

interactive_apply() {
    # Gather profiles
    profiles=()
    for profile_file in "$PROFILES_DIR"/*.code-profile; do
        [ -e "$profile_file" ] || continue
        filename=$(basename "$profile_file")
        profiles+=("${filename%.code-profile}")
    done

    if [ ${#profiles[@]} -eq 0 ]; then
        echo -e "${RED}No profiles found in $PROFILES_DIR${NC}"
        exit 1
    fi

    arrow_menu "Which profile do you want to apply?" chosen_idx "${profiles[@]}"
    local chosen_profile="${profiles[$chosen_idx]}"

    local modes=("sync" "replace")
    local mode_labels=("Sync (Merges with current settings, keeps existing extensions)" "Replace (Uninstalls all current extensions, overwrites settings)")
    
    echo ""
    arrow_menu "Do you want to Sync or Replace?" mode_idx "${mode_labels[@]}"
    local chosen_mode="${modes[$mode_idx]}"
    
    echo ""
    apply_profile "$chosen_profile" "$chosen_mode"
}

# Main Menu
while true; do
    options=("Apply a Profile to VS Code" "Exit")
    arrow_menu "Select an action:" opt_idx "${options[@]}"
    
    echo ""
    case $opt_idx in
        0) interactive_apply ;;
        1) echo "Goodbye!"; exit 0 ;;
    esac
    echo ""
done
