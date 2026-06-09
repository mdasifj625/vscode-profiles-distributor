**Profile Report**

- **Default profile**: [profiles/Default.code-profile](profiles/Default.code-profile)
    - **Extensions (61)**: aaron-bond.better-comments, batisteo.vscode-django, bierner.markdown-emoji, bradlc.vscode-tailwindcss, christian-kohler.npm-intellisense, christian-kohler.path-intellisense, codezombiech.gitignore, dbaeumer.vscode-eslint, devzstudio.emoji-snippets, digitalbrainstem.javascript-ejs-support, docker.docker, donjayamanne.python-environment-manager, donjayamanne.python-extension-pack, eamodio.gitlens, ecmel.vscode-html-css, editorconfig.editorconfig, esbenp.prettier-vscode, formulahendry.auto-rename-tag, formulahendry.code-runner, foxundermoon.shell-format, george-alisson.html-preview-vscode, github.github-vscode-theme, github.vscode-github-actions, gruntfuggly.todo-tree, humao.rest-client, jasonnutter.search-node-modules, kevinrose.vsc-python-indent, mikestead.dotenv, ms-azuretools.vscode-containers, ms-azuretools.vscode-docker, ms-python.debugpy, ms-python.python, ms-python.vscode-pylance, ms-python.vscode-python-envs, ms-vscode-remote.remote-ssh, ms-vscode-remote.remote-ssh-edit, ms-vscode-remote.remote-wsl, ms-vscode.azure-repos, ms-vscode.cmake-tools, ms-vscode.cpp-devtools, ms-vscode.cpptools-extension-pack, ms-vscode.cpptools-themes, ms-vscode.live-server, ms-vscode.remote-explorer, ms-vscode.remote-repositories, ms-vscode.test-adapter-converter, ms-vsliveshare.vsliveshare, njpwerner.autodocstring, orta.vscode-jest, phantom.gcc-md, pkief.material-icon-theme, redhat.java, redhat.vscode-yaml, ritwickdey.liveserver, streetsidesoftware.code-spell-checker, syler.sass-indented, vscjava.vscode-java-debug, wholroyd.jinja, wix.vscode-import-cost, xabikos.javascriptsnippets, yzhang.markdown-all-in-one
    - **Heavy / runtime-impact**: ms-python.python, ms-python.vscode-pylance, ms-python.debugpy, redhat.java, vscjava.vscode-java-debug, ms-azuretools.vscode-containers, ms-azuretools.vscode-docker, ms-vsliveshare.vsliveshare, ms-vscode.cpptools-extension-pack, ms-vscode.cmake-tools

- **Python profile**: [profiles/Python.code-profile](profiles/Python.code-profile)
    - **Extensions (15)**: github.github-vscode-theme, pkief.material-icon-theme, eamodio.gitlens, editorconfig.editorconfig, codezombiech.gitignore, github.copilot-chat, donjayamanne.python-environment-manager, donjayamanne.python-extension-pack, ms-python.debugpy, ms-python.python, ms-python.vscode-pylance, ms-python.vscode-python-envs, njpwerner.autodocstring, kevinrose.vsc-python-indent, hbenl.vscode-test-explorer
    - **Heavy / runtime-impact**: ms-python.python, ms-python.vscode-pylance, ms-python.debugpy, github.copilot-chat

- **C C++ profile**: [profiles/C C++.code-profile](profiles/C C++.code-profile)
    - **Extensions (11)**: github.github-vscode-theme, pkief.material-icon-theme, eamodio.gitlens, editorconfig.editorconfig, codezombiech.gitignore, github.copilot-chat, ms-vscode.cmake-tools, ms-vscode.cpp-devtools, ms-vscode.cpptools-extension-pack, ms-vscode.cpptools-themes, phantom.gcc-md
    - **Heavy / runtime-impact**: ms-vscode.cpptools-extension-pack, ms-vscode.cmake-tools, github.copilot-chat

- **JavaScript TypeScript profile**: [profiles/JavaScript TypeScript.code-profile](profiles/JavaScript TypeScript.code-profile)
    - **Status**: empty / placeholder (no extensions)

**Observations**

- None of the profiles declare `basedOn` inheritance — they appear standalone.
- `Default` is broad and includes many heavy language and remote tools; not minimal for a production-conservative profile.
- `Python` and `C C++` focus on language toolchains and include the expected heavy components (language servers, debuggers).

**Recommendations (production-ready / minimal)**

- Create a minimal shared base profile with only essential UI and productivity extensions: `editorconfig.editorconfig`, `codezombiech.gitignore`, `eamodio.gitlens` (optional), theme/icon if desired.
- Split language/tooling into per-language profiles (e.g., `Python-lite`, `CPP-lite`) that only enable language servers and debuggers when required by the developer.
- Avoid enabling remote/container tooling (`ms-azuretools.vscode-containers`, `ms-vscode-remote.*`) in default profiles unless the team uses them actively.
- Treat `github.copilot-chat`, `ms-vsliveshare.vsliveshare`, and language servers as opt-in because they run background services and increase memory/CPU.

**Testing steps to measure impact**

1. Backup current extensions or export the profile (you already have exports in `profiles/`).
2. Start VS Code with a clean user profile (run VS Code's `--user-data-dir` pointing to an empty folder) and measure startup time and memory.
3. Apply each profile and measure delta in startup time and resident memory (Task Manager / Process Explorer). Use the existing `scripts/apply-profile.sh` to apply profiles if that script is configured.

Example commands (Windows Git Bash / WSL) — start clean and measure:

```bash
# start VS Code with empty user-data and extension-dir (example paths)
code --user-data-dir="$PWD/tmp-vscode-user" --extensions-dir="$PWD/tmp-vscode-exts"
```

Apply a profile using your `scripts/apply-profile.sh` (if it supports the profile path):

```bash
scripts/apply-profile.sh profiles/Default.code-profile
```

Measure resident memory with Task Manager or `code --status` and compare.

**Next steps I can take**

- Produce a minimal `production.code-profile` removing non-essential heavy extensions.
- Generate a per-profile CSV or JSON summary for automation.

If you want, I will generate `production.code-profile` now and a CSV summary for automation.
