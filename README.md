# VS Code Profiles Distributor

A lightweight tool to manage and distribute VS Code profiles across different environments. This project uses an **automatic inheritance model** to ensure a clean, maintainable, and non-redundant configuration.

## 🏗️ Architecture: Automatic Inheritance

The system is designed around a **"Base & Extension"** philosophy. You never have to manually duplicate settings.

### How it works:
1.  **Default Profile (`profiles/Default.code-profile`)**: This is your "Source of Truth." It contains universal settings (fonts, themes, terminal) and common extensions (GitLens, EditorConfig, Material Icons).
2.  **Domain Profiles**: Profiles like `Python` or `JavaScript TypeScript` contain **only** domain-specific logic.
3.  **The Auto-Merge**: When you apply any profile other than `Default`, the script automatically:
    *   Loads all settings and extensions from `Default`.
    *   Overlays the specific domain profile on top.
    *   Installs the union of both extension lists.

**Benefit**: Change your font size or theme in `Default.code-profile`, and it automatically updates across **all** your specialized profiles next time you apply them.

## 🚀 Getting Started

### Prerequisites

-   **VS Code**: The `code` command must be in your PATH.
-   **Linux/WSL/macOS**: `jq` is required for JSON processing.
-   **Windows**: PowerShell 5.1+ or higher.

### Usage

#### Bash (Linux, WSL, macOS, Git Bash)
```bash
chmod +x vsprofile.sh
./vsprofile.sh
```
> **Note for WSL Users**: Running `vsprofile.sh` inside WSL will automatically detect both your **Windows host** and the **WSL instance**. It will apply settings and sync/replace extensions for both environments simultaneously, ensuring a consistent remote development experience.

#### PowerShell (Windows)
```powershell
.\vsprofile.ps1
```
> **Note**: Running on native Windows (PowerShell or Git Bash) will only impact your Windows VS Code settings.

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
