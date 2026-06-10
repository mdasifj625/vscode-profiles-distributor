# VS Code Profiles Distributor

A lightweight tool to manage and distribute VS Code profiles across different environments. This project uses an **automatic inheritance model** to ensure a clean, maintainable, and non-redundant configuration.

## 🏗️ Architecture: Automatic Inheritance & Native Integration

The system is designed around a **"Base & Extension"** philosophy with **Native VS Code Profile Support**.

### How it works:
1.  **Default Profile (`profiles/Default.code-profile`)**: This is your "Source of Truth" for universal settings and extensions.
2.  **Domain Profiles**: Profiles like `Python` or `JavaScript TypeScript` in this repo contain only domain-specific logic.
3.  **Native Integration**: When you apply a profile:
    *   The script **detects if the profile exists** in your native VS Code system (by auditing `storage.json`).
    *   **Manual Guidance**: If the profile is missing from VS Code, the script will provide a clear guide and exactly what name to use. You can then create it manually in the VS Code UI and click **"Continue"** in the script to proceed.
    *   **Targeted Application**: Once the native profile is detected, the script uses the `--profile` CLI flag to target that specific environment, ensuring your main "Default" setup remains untouched unless explicitly modified.
4.  **The Auto-Merge**: The script automatically merges `Default` with the domain profile at runtime before applying.

**Benefit**: You get a clean, official VS Code profile system that is fully managed and synchronized via this repository.

## 🚀 Getting Started

### Prerequisites

-   **VS Code**: The `code` command must be in your PATH.
-   **Linux/WSL/macOS**: `jq` is required for JSON processing.
-   **Windows**: PowerShell 5.1+ or higher.

### Usage

#### Bash (Linux, WSL, macOS, Git Bash)
```bash
chmod +x vsprofile.sh
./vsprofile.sh [profile-name]
```
> **Note for WSL Users**: Running `vsprofile.sh` inside WSL automatically targets both your **Windows host** and the **WSL instance**. It will detect/create native profiles on both sides and keep them in sync.

#### PowerShell (Windows)
```powershell
.\vsprofile.ps1
```
> **Native Profile Detection**: If you select a profile from the repo that doesn't exist in your Windows VS Code setup, the script will offer to create it for you on the fly.

### Modes of Application

1.  **Sync (Recommended)**: Deep merges the selected profile (merged with `Default`) with your current VS Code settings. It preserves your existing manual configurations while adding the profile's tools.
2.  **Replace**: A destructive operation. It **uninstalls all current extensions** and overwrites settings completely with the selected profile (merged with `Default`). Perfect for resetting a machine to a specific dev environment.

## 📂 Profile Structure

Profiles are stored in `profiles/` as `.code-profile` files. Keep them lean!

```json
{
  "name": "Python",
  "settings": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "extensions": [
    "ms-python.python",
    "charliermarsh.ruff"
  ]
}
```

## 🛠️ Included Profiles

-   **Default**: Base UI, terminal, and git configuration. Includes **Docker**, **SonarLint**, **Live Server**, and **Path Intellisense** as universal productivity tools.
-   **JavaScript TypeScript**: Full-stack support (Node, React, Next.js, Prisma, Tailwind). Includes **Expo Tools** for mobile and **Sass** support.
-   **Python**: Data science (**Jupyter**), modern linting (**Ruff**), and web frameworks (Django/Jinja2).
-   **C C++**: Advanced IntelliSense (**Clangd**), **CMake**, **Bazel**, and **Doxygen** documentation support.
