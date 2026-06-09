# VS Code Profiles Distributor

## Overview
The VS Code Profiles Distributor is a lightweight, dependency-free toolkit to streamline the management and distribution of Visual Studio Code profiles. 

It completely removes the overhead of Node.js and TypeScript, using purely native **Bash** and **PowerShell** scripts. It provides an interactive terminal UI while natively understanding your environment, automatically bridging the gap between Windows and WSL setups seamlessly!

## Project Structure
```
vscode-profiles-distributor
├── profiles
│   ├── Default.code-profile        # Minimal setup for all profiles
│   ├── Python.code-profile         # Python-specific settings and extensions
│   ├── C C++.code-profile          # C/C++ specific settings and extensions
│   └── JavaScript TypeScript.code-profile # JavaScript/TypeScript specific settings and extensions
├── vsprofile.sh                    # Interactive Bash application (Linux/Mac/WSL)
├── vsprofile.ps1                   # Interactive PowerShell application (Windows Native)
├── .gitignore                      # Files and directories to ignore by Git
└── README.md                       # Project documentation
```

## Getting Started

### For Linux / Mac / WSL
The bash script (`vsprofile.sh`) relies on `jq` to reliably deep-merge JSON configurations without breaking your settings.
1. The script will attempt to automatically install `jq` for you if you run it on Ubuntu/WSL.
2. Run the script:
   ```bash
   ./vsprofile.sh
   ```

### For Windows (Native PowerShell)
If you are on Windows and don't want to install `jq` or use Git Bash, use the native PowerShell equivalent (`vsprofile.ps1`)! It uses Windows' built-in JSON parsers with zero dependencies.
1. Open PowerShell and run:
   ```powershell
   .\vsprofile.ps1
   ```
*(Note: You may need to run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` if your system restricts executing local PowerShell scripts).*

---

## Interactive Features
Running either script presents a beautiful, selection-based interactive menu directly in your terminal:

### 1. Apply a Profile to VS Code
Select this to push a specific profile to your actual, running VS Code setup on your computer. You will be prompted to choose a profile (e.g., `Python`, `C C++`, or `Default`).

Once selected, you choose an application mode:
- **Sync**: Safely deep-merges the selected profile's settings with your *existing* VS Code settings. It keeps your installed extensions and only adds new ones.
- **Replace**: Acts as a fresh start. It aggressively uninstalls *all* currently installed extensions, completely overwrites your local settings, and installs *only* the extensions defined in your selected profile.

### 2. Sync all Profiles with Default Profile
Selecting this option takes the configurations inside `Default.code-profile` and dynamically deep-merges them into `Python.code-profile`, `C C++.code-profile`, and all other files in your `profiles/` directory.

### Windows & WSL Interoperability
If you run the bash script inside **WSL**, it automatically detects the Microsoft subsystem layer. It intelligently routes your settings updates specifically to your Windows UI (`AppData/Roaming/Code/User`) using `wslpath` so your VS Code GUI updates instantly, while simultaneously routing the `code --install-extension` commands to the WSL backend, guaranteeing extensions like C++ and Python are installed right where they need to be!

## License
This project is licensed under the MIT License.