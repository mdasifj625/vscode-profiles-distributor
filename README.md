# VS Code Profiles Distributor

## Overview
The VS Code Profiles Distributor is a project designed to streamline the management and distribution of Visual Studio Code profiles. It allows users to maintain a consistent development environment across different programming languages by providing tailored profiles for Python, C/C++, and JavaScript/TypeScript, all based on a minimal default configuration.

The tool provides a unified CLI built with TypeScript that safely merges settings and intelligently applies profiles to your local VS Code setup, automatically detecting your OS to place configuration files in the appropriate directories and executing extension installation commands.

## Project Structure
```
vscode-profiles-distributor
├── profiles
│   ├── Default.code-profile        # Minimal setup for all profiles
│   ├── Python.code-profile         # Python-specific settings and extensions
│   ├── C C++.code-profile          # C/C++ specific settings and extensions
│   └── JavaScript TypeScript.code-profile # JavaScript/TypeScript specific settings and extensions
├── src
│   └── index.ts                    # Unified CLI application
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

3. **Synchronize Profiles**
   If you have updated the `Default.code-profile` or any specific profile, you can deep merge the default settings with all other profiles to keep them up to date:
   ```bash
   npm run sync
   ```

4. **Apply a Profile**
   Apply a specific profile to your local VS Code installation. This will intelligently overwrite your `settings.json`, `keybindings.json`, and automatically run the CLI commands to install all necessary extensions:
   ```bash
   npm run apply -- "C C++"
   ```
   *(Replace `"C C++"` with the name of the profile you want to apply).*

## Profiles
- **Default Profile**: Contains essential settings and extensions common to all profiles.
- **Python Profile**: Extends the Default profile with Python-specific configurations, including linting and formatting.
- **C/C++ Profile**: Extends the Default profile with settings tailored for C/C++ development, including IntelliSense and formatting options.
- **JavaScript/TypeScript Profile**: Extends the Default profile with configurations for JavaScript and TypeScript, including ESLint and Prettier.

## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.