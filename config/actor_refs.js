import path from 'path';
import { fileURLToPath } from 'url';
import { readFileSync } from 'fs';

// Define __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Synchronously load and parse the JSON file without using import assertions
const canisterIds = JSON.parse(
	readFileSync(path.join(__dirname, '../.dfx/local/canister_ids.json'), 'utf8')
);

// Canister names to load
const canisterNames = [
	'explore',
	'creator',
	'username_registry',
	'file_storage',
	'file_scaling_manager'
];

// Build the canister IDs object from the parsed JSON data
export const canister_ids = canisterNames.reduce((acc, name) => {
	// Adjust the key access as needed based on the JSON structure
	acc[name] = canisterIds[name].local;
	return acc;
}, {});

// Asynchronously load interface definitions from the corresponding did files
async function loadInterfaces() {
	const interfaces = {};
	for (const name of canisterNames) {
		const idlFactoryPath = path.join(__dirname, `../.dfx/local/canisters/${name}/service.did.js`);
		try {
			const module = await import(idlFactoryPath);
			interfaces[name] = module.idlFactory;
		} catch (error) {
			console.error(`Error loading interface for ${name}:`, error);
			// Handle the error as needed (for example, skip this module)
		}
	}
	return interfaces;
}

// Export a function that returns a promise for the loaded interfaces
export function getInterfaces() {
	return loadInterfaces();
}
