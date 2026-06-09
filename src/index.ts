import { syncProfiles } from './syncProfiles';

const main = async () => {
    try {
        await syncProfiles();
        console.log('Profiles synchronized successfully.');
    } catch (error) {
        console.error('Error synchronizing profiles:', error);
    }
};

main();