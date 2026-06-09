# VS Code Profiles Distributor

## Overview
The VS Code Profiles Distributor is a project designed to streamline the management and distribution of Visual Studio Code profiles. It allows users to maintain a consistent development environment across different programming languages by providing tailored profiles for Python, C/C++, and JavaScript/TypeScript, all based on a minimal default configuration.

The tool provides a unified, **interactive CLI** built with TypeScript and `inquirer` that safely manages settings, automatically installs extensions, and elegantly propagates default configurations across your entire profile suite.

## Project Structure
```
vscode-profiles-distributor
├── profiles
│   ├── Default.code-profile        # Minimal setup for all profiles
│   ├── Python.code-profile         # Python-specific settings and extensions
│   ├── C C++.code-profile          # C/C++ specific settings and extensions
│   └── JavaScript TypeScript.code-profile # JavaScript/TypeScript specific settings and extensions
├── src
│   └── index.ts                    # Unified interactive CLI application
├── .gitignore                      # Files and directories to ignore by Git
├── package.json                    # npm configuration file
├── tsconfig.json                   # TypeScript configuration file
└── README.md                       # Project documentation
```

## Getting Started
To get started with the VS Code Profiles Distributor, follow these steps:

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd vscode-profiles-distributor
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Launch the Interactive CLI**
   Instead of remembering multiple commands, simply start the tool:
   ```bash
   npm start
   ```

## Interactive Features

When you run `npm start`, you will be greeted by an interactive terminal menu:

### 1. Apply a Profile to VS Code
Select this to push a specific profile to your actual, running VS Code setup on your computer. You will be prompted to choose a profile (e.g. `Python`, `C C++`, or `Default`).

Once selected, you must choose an application mode:
- **Sync**: Safely merges the selected profile's settings with your *existing* VS Code settings. It keeps all of your currently installed extensions and only adds new ones defined by the profile.
- **Replace**: Acts as a fresh start. It aggressively uninstalls *all* currently installed extensions in your VS Code editor, completely overwrites your local settings, and installs *only* the extensions defined in your selected profile. This is ideal when migrating to a brand-new machine or attempting to clean up a cluttered editor.

### 2. Sync all Profiles with Default Profile
Your `Default.code-profile` acts as a "Base Template" containing your favorite font sizes, color themes, and standard extensions (like Prettier).

Selecting this option takes the configurations inside `Default.code-profile` and dynamically injects/merges them into `Python.code-profile`, `C C++.code-profile`, and all other files in your `profiles/` directory. If you change a universal setting in the Default profile, this command propagates it everywhere instantly.

## Profiles Included
- **Default Profile**: Contains essential settings and extensions common to all profiles.
- **Python Profile**: Extends the Default profile with Python-specific configurations, including linting and formatting.
- **C/C++ Profile**: Extends the Default profile with settings tailored for C/C++ development, including IntelliSense and formatting options.
- **JavaScript/TypeScript Profile**: Extends the Default profile with configurations for JavaScript and TypeScript, including ESLint and Prettier.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.