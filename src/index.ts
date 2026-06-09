#!/usr/bin/env tsx

import { Command } from 'commander';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import os from 'os';
import inquirer from 'inquirer';

const program = new Command();

const PROFILES_DIR = path.resolve(process.cwd(), 'profiles');

function getVSCodeUserDataPath(): string {
    const platform = os.platform();
    const homeDir = os.homedir();

    if (platform === 'win32') {
        return path.join(process.env.APPDATA || path.join(homeDir, 'AppData', 'Roaming'), 'Code', 'User');
    } else if (platform === 'darwin') {
        return path.join(homeDir, 'Library', 'Application Support', 'Code', 'User');
    } else {
        return path.join(homeDir, '.config', 'Code', 'User');
    }
}

function mergeObjects(target: any, source: any): any {
    if (typeof target !== 'object' || target === null) return source;
    if (typeof source !== 'object' || source === null) return source;

    if (Array.isArray(target) && Array.isArray(source)) {
        return Array.from(new Set([...target, ...source]));
    }

    const output = { ...target };
    Object.keys(source).forEach(key => {
        if (typeof source[key] === 'object' && source[key] !== null) {
            output[key] = mergeObjects(target[key] || (Array.isArray(source[key]) ? [] : {}), source[key]);
        } else {
            output[key] = source[key];
        }
    });
    return output;
}

function getInstalledExtensions(): string[] {
    try {
        const output = execSync('code --list-extensions', { encoding: 'utf-8' });
        return output.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    } catch (e) {
        console.warn('Could not list current extensions.');
        return [];
    }
}

function uninstallAllExtensions() {
    const extList = getInstalledExtensions();
    if (extList.length > 0) {
        console.log(`Uninstalling ${extList.length} current extensions...`);
        for (const ext of extList) {
            try {
                console.log(`Uninstalling: ${ext}`);
                execSync(`code --uninstall-extension ${ext} --force`, { stdio: 'ignore' });
            } catch (e) {
                console.warn(`Failed to uninstall ${ext}`);
            }
        }
    }
}

async function handleApply(profileName: string, dir: string, mode: 'sync' | 'replace') {
    let profilePath = path.join(dir, `${profileName}.code-profile`);

    if (!fs.existsSync(profilePath)) {
        profilePath = path.join(dir, profileName);
        if (!fs.existsSync(profilePath)) {
            console.error(`Profile not found: ${profileName}`);
            process.exit(1);
        }
    }

    const profileContent = fs.readFileSync(profilePath, 'utf-8');
    let profile: any;
    try {
        profile = JSON.parse(profileContent);
    } catch(e) {
        console.error(`Profile ${profileName} has invalid JSON.`);
        process.exit(1);
    }

    const userDataPath = getVSCodeUserDataPath();

    if (!fs.existsSync(userDataPath)) {
        fs.mkdirSync(userDataPath, { recursive: true });
    }

    const settingsPath = path.join(userDataPath, 'settings.json');
    const keybindingsPath = path.join(userDataPath, 'keybindings.json');

    if (mode === 'replace') {
        uninstallAllExtensions();
        
        if (profile.settings) {
            fs.writeFileSync(settingsPath, JSON.stringify(profile.settings, null, '\t'));
            console.log(`Settings replaced at ${settingsPath}`);
        } else {
            fs.writeFileSync(settingsPath, '{}');
        }

        if (profile.keybindings && Array.isArray(profile.keybindings)) {
            fs.writeFileSync(keybindingsPath, JSON.stringify(profile.keybindings, null, '\t'));
            console.log(`Keybindings replaced at ${keybindingsPath}`);
        } else {
            fs.writeFileSync(keybindingsPath, '[]');
        }
    } else if (mode === 'sync') {
        if (profile.settings) {
            let existingSettings = {};
            if (fs.existsSync(settingsPath)) {
                try {
                    existingSettings = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'));
                } catch(e) {}
            }
            const newSettings = mergeObjects(existingSettings, profile.settings);
            fs.writeFileSync(settingsPath, JSON.stringify(newSettings, null, '\t'));
            console.log(`Settings synced to ${settingsPath}`);
        }

        if (profile.keybindings && Array.isArray(profile.keybindings) && profile.keybindings.length > 0) {
            let existingKeybindings: any[] = [];
            if (fs.existsSync(keybindingsPath)) {
                try {
                    existingKeybindings = JSON.parse(fs.readFileSync(keybindingsPath, 'utf-8'));
                } catch(e) {}
            }
            const newKeybindings = mergeObjects(existingKeybindings, profile.keybindings);
            fs.writeFileSync(keybindingsPath, JSON.stringify(newKeybindings, null, '\t'));
            console.log(`Keybindings synced to ${keybindingsPath}`);
        }
    }

    if (profile.extensions) {
        let extList: string[] = [];
        if (Array.isArray(profile.extensions)) {
            extList = profile.extensions;
        } else if (profile.extensions.extensions && Array.isArray(profile.extensions.extensions)) {
            extList = profile.extensions.extensions.map((ext: any) => ext.id);
        }

        if (extList.length > 0) {
            console.log(`Installing ${extList.length} extensions...`);
            for (const ext of extList) {
                try {
                    console.log(`Installing extension: ${ext}`);
                    execSync(`code --install-extension ${ext} --force`, { stdio: 'inherit' });
                } catch (e: any) {
                    console.warn(`Failed to install extension ${ext}`);
                }
            }
        }
    }

    console.log(`Profile '${profileName}' applied successfully in ${mode} mode.`);
}

function runSync(dir: string) {
    const defaultPath = path.join(dir, 'Default.code-profile');

    if (!fs.existsSync(defaultPath)) {
        console.error('Default profile not found at', defaultPath);
        process.exit(1);
    }

    const defaultProfile = JSON.parse(fs.readFileSync(defaultPath, 'utf-8'));
    const files = fs.readdirSync(dir);

    files.forEach(file => {
        if (file.endsWith('.code-profile') && file !== 'Default.code-profile') {
            const profilePath = path.join(dir, file);
            const fileContent = fs.readFileSync(profilePath, 'utf-8');

            if (!fileContent.trim()) {
                console.warn(`Skipping empty profile: ${file}`);
                return;
            }

            let profile;
            try {
                profile = JSON.parse(fileContent);
            } catch (e) {
                console.error(`Invalid JSON in profile ${file}, skipping.`);
                return;
            }

            const updatedProfile = {
                ...defaultProfile,
                ...profile,
                settings: mergeObjects(defaultProfile.settings || {}, profile.settings || {}),
                extensions: mergeObjects(defaultProfile.extensions || [], profile.extensions || []),
                keybindings: mergeObjects(defaultProfile.keybindings || [], profile.keybindings || [])
            };

            fs.writeFileSync(profilePath, JSON.stringify(updatedProfile, null, '\t'));
            console.log(`Synchronized profile: ${file}`);
        }
    });

    console.log('All profiles synchronized successfully.');
}

async function launchApplyInteractive(dir: string) {
    if (!fs.existsSync(dir)) {
        console.error(`Profiles directory not found: ${dir}`);
        process.exit(1);
    }
    
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.code-profile')).map(f => f.replace('.code-profile', ''));
    
    if (files.length === 0) {
        console.error(`No profiles found in ${dir}`);
        process.exit(1);
    }

    const answers = await inquirer.prompt([
        {
            type: 'select',
            name: 'selectedProfile',
            message: 'Which profile do you want to apply?',
            choices: files
        },
        {
            type: 'select',
            name: 'mode',
            message: 'Do you want to Sync or Replace?',
            choices: [
                { name: 'Sync (Merges with current settings, keeps existing extensions)', value: 'sync' },
                { name: 'Replace (Uninstalls all current extensions, overwrites settings)', value: 'replace' }
            ]
        }
    ]);

    await handleApply(answers.selectedProfile, dir, answers.mode);
}

async function launchMainMenu() {
    const answer = await inquirer.prompt([
        {
            type: 'select',
            name: 'action',
            message: 'Welcome to VS Code Profiles Distributor! What would you like to do?',
            choices: [
                { name: 'Apply a Profile to VS Code', value: 'apply' },
                { name: 'Sync all Profiles with Default Profile', value: 'sync' },
                { name: 'Exit', value: 'exit' }
            ]
        }
    ]);

    if (answer.action === 'apply') {
        await launchApplyInteractive(PROFILES_DIR);
    } else if (answer.action === 'sync') {
        runSync(PROFILES_DIR);
    } else {
        process.exit(0);
    }
}

// Check if arguments were passed directly to Commander or if we should show the interactive menu
if (process.argv.length === 2) {
    // No arguments passed, launch the interactive main menu
    launchMainMenu().catch(err => {
        console.error(err);
        process.exit(1);
    });
} else {
    // Arguments passed, use Commander for CLI shortcuts
    program
        .name('vsprofile')
        .description('A tool to distribute and synchronize VS Code profiles')
        .version('1.0.0');

    program.command('sync')
        .description('Synchronize all profiles in the profiles directory with the default profile')
        .option('-d, --dir <directory>', 'Profiles directory', PROFILES_DIR)
        .action((options) => {
            runSync(path.resolve(options.dir));
        });

    program.command('apply')
        .description('Apply a specific VS Code profile to your local setup interactively or manually')
        .argument('[profileName]', 'Name of the profile (e.g. "Default", "C C++"). Leave empty for interactive mode.')
        .option('-d, --dir <directory>', 'Profiles directory', PROFILES_DIR)
        .option('--replace', 'Replace existing setup instead of syncing')
        .action(async (profileName, options) => {
            const dir = path.resolve(options.dir);
            if (!profileName) {
                await launchApplyInteractive(dir);
            } else {
                const mode = options.replace ? 'replace' : 'sync';
                await handleApply(profileName, dir, mode);
            }
        });

    program.parse(process.argv);
}