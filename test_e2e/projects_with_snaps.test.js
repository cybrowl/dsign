import { describe, test, expect, beforeAll } from 'vitest';
import { config } from 'dotenv';
import { canister_ids, getInterfaces } from '../config/actor_refs';
import { parseIdentity } from './actor_identity.cjs';
import { getActor } from './actor.cjs';

import { FileStorage } from '../src/ui/utils/file_storage';

// Configure environment variables
config();

// Identities
let nikola_identity = parseIdentity(process.env.NIKOLA_IDENTITY);
let linky_identity = parseIdentity(process.env.LINKY_IDENTITY);
let anonymous_identity = null;

let interfaces = {};

let username_registry_actor = {};
let file_scaling_manager_actor = {};
let file_storage_actor_lib = {};

// Helper function to mimic the File Web API object in Node.js

describe('Projects With Snaps', () => {
	beforeAll(async () => {
		interfaces = await getInterfaces();

		// Setup Username Registry Actors
		username_registry_actor.nikola = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			nikola_identity
		);
		username_registry_actor.linky = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			linky_identity
		);
		username_registry_actor.anonymous = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			anonymous_identity
		);

		// Setup File Scaling Manager Actors
		file_scaling_manager_actor.nikola = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			nikola_identity
		);
		file_scaling_manager_actor.linky = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			linky_identity
		);
		file_scaling_manager_actor.anonymous = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			anonymous_identity
		);

		const fs_canister_id = await file_scaling_manager_actor.nikola.get_current_canister_id();
		const file_storage_actor = await getActor(
			fs_canister_id,
			interfaces.file_storage,
			nikola_identity
		);

		file_storage_actor_lib.nikola = new FileStorage(file_storage_actor);
	});

	// Example Test: Check version number of UsernameRegistry[nikola]
	test('UsernameRegistry[nikola].version(): => #ok - Version Number', async () => {
		const version_num = await username_registry_actor.nikola.version();
		expect(version_num).toBe(1n);
	});
});
