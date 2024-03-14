const canisterIds = await import('../.dfx/local/canister_ids.json', {
	assert: { type: 'json' }
});
import path from 'path';
import { fileURLToPath } from 'url';

// Define __dirname for ES modules
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Canister names
const canisterNames = [
	'explore',
	'creator',
	'username_registry',
	'file_storage',
	'file_scaling_manager'
];

// Synchronously load canister IDs
export const canister_ids = canisterNames.reduce((acc, name) => {
	acc[`${name}`] = canisterIds.default[name].local;
	return acc;
}, {});

// Asynchronously load interfaces
async function loadInterfaces() {
	const interfaces = {};
	for (const name of canisterNames) {
		const idlFactoryPath = path.join(__dirname, `../.dfx/local/canisters/${name}/service.did.js`);
		try {
			const module = await import(idlFactoryPath);
			interfaces[name] = module.idlFactory;
		} catch (error) {
			console.error(`Error loading interface for ${name}:`, error);
			// Handle the error as needed, e.g., skip this module, throw an error, etc.
		}
	}
	return interfaces;
}

// Export a function that returns a promise of the loaded interfaces
export function getInterfaces() {
	return loadInterfaces();
}
