// This file includes utility functions for profile synchronization, such as reading and writing profile files and handling configuration merges.

import fs from 'fs';
import path from 'path';

export const readProfileFile = (filePath: string): any => {
    const absolutePath = path.resolve(filePath);
    const data = fs.readFileSync(absolutePath, 'utf-8');
    return JSON.parse(data);
};

export const writeProfileFile = (filePath: string, data: any): void => {
    const absolutePath = path.resolve(filePath);
    fs.writeFileSync(absolutePath, JSON.stringify(data, null, 4));
};

export const mergeProfiles = (defaultProfile: any, specificProfile: any): any => {
    return {
        ...defaultProfile,
        settings: {
            ...defaultProfile.settings,
            ...specificProfile.settings,
        },
        extensions: {
            ...defaultProfile.extensions,
            ...specificProfile.extensions,
        },
    };
};