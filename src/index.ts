#!/usr/bin/env tsx

import { Command } from 'commander';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import os from 'os';

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

program
    .name('vsprofile')
    .description('A tool to distribute and synchronize VS Code profiles')
    .version('1.0.0');

program.command('sync')
    .description('Synchronize all profiles in the profiles directory with the default profile')
    .option('-d, --dir <directory>', 'Profiles directory', PROFILES_DIR)
    .action((options) => {
        const dir = path.resolve(options.dir);
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
    });

program.command('apply')
    .description('Apply a specific VS Code profile to your local setup')
    .argument('<profileName>', 'Name of the profile (e.g. "Default", "C C++")')
    .option('-d, --dir <directory>', 'Profiles directory', PROFILES_DIR)
    .action((profileName, options) => {
        const dir = path.resolve(options.dir);
        let profilePath = path.join(dir, `${profileName}.code-profile`);

        if (!fs.existsSync(profilePath)) {
            profilePath = path.join(dir, profileName);
            if (!fs.existsSync(profilePath)) {
                console.error(`Profile not found: ${profileName}`);
                process.exit(1);
            }
        }

        const profile = JSON.parse(fs.readFileSync(profilePath, 'utf-8'));
        const userDataPath = getVSCodeUserDataPath();

        if (!fs.existsSync(userDataPath)) {
            fs.mkdirSync(userDataPath, { recursive: true });
        }

        // Write settings
        if (profile.settings) {
            const settingsPath = path.join(userDataPath, 'settings.json');
            fs.writeFileSync(settingsPath, JSON.stringify(profile.settings, null, '\t'));
            console.log(`Settings applied to ${settingsPath}`);
        }

        // Write keybindings
        if (profile.keybindings && Array.isArray(profile.keybindings) && profile.keybindings.length > 0) {
            const keybindingsPath = path.join(userDataPath, 'keybindings.json');
            fs.writeFileSync(keybindingsPath, JSON.stringify(profile.keybindings, null, '\t'));
            console.log(`Keybindings applied to ${keybindingsPath}`);
        }

        // Install extensions
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

        console.log(`Profile '${profileName}' applied successfully.`);
    });

program.parse(process.argv);