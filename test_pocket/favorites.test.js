import { Principal } from '@dfinity/principal';
import { Actor, PocketIc, createIdentity } from '@hadronous/pic';
import { IDL } from '@dfinity/candid';
import { resolve } from 'node:path';
import { describe, test, expect, beforeAll } from 'vitest';
import {
	_SERVICE,
	idlFactory as idlFactoryUsernameRegistry,
	init
} from '../.dfx/local/canisters/username_registry/service.did.js';

import {
	_SERVICE,
	idlFactory as idlFactoryCreator,
	init as initCreator
} from '../.dfx/local/canisters/creator/service.did.js';

const WASM_PATH_USERNAME_REGISTRY = resolve(
	__dirname,
	'..',
	'..',
	'dsign',
	'.dfx',
	'local',
	'canisters',
	'username_registry',
	'username_registry.wasm'
);

const WASM_PATH_CREATOR = resolve(
	__dirname,
	'..',
	'..',
	'dsign',
	'.dfx',
	'local',
	'canisters',
	'creator',
	'creator.wasm'
);

describe('Feedback', async () => {
	const pic = await PocketIc.create();

	let actor_username_registry = {};
	let actor_creator = {};

	const alice = createIdentity('alice_pass');
	const link = createIdentity('link_pass');

	beforeAll(async () => {
		const setup_args_username_registry = {
			idlFactory: idlFactoryUsernameRegistry,
			wasm: WASM_PATH_USERNAME_REGISTRY
		};

		const fixture_username_registry = await pic.setupCanister(setup_args_username_registry);

		actor_username_registry = fixture_username_registry.actor;

		//DELETE PROFILES TO BE USED
		actor_username_registry.setIdentity(alice);
		await actor_username_registry.delete_profile();

		actor_username_registry.setIdentity(link);
		await actor_username_registry.delete_profile();
	});

	test('UsernameRegistry[link].version(): => #ok - Version Number', async () => {
		const version_num = await actor_username_registry.version();
		await actor_username_registry.init();

		expect(version_num).toBe(4n);
	});

	test('UsernameRegistry[alice].create_profile(): with valid username => #ok - Username', async () => {
		actor_username_registry.setIdentity(alice);
		const { ok: username, err: error } = await actor_username_registry.create_profile('alice');

		const { ok: username_info } = await actor_username_registry.get_info_by_username(username);

		const creator_principal = Principal.fromText(username_info.canister_id);

		actor_creator = pic.createActor(idlFactoryCreator, creator_principal);

		expect(username.length).toBeGreaterThan(1);
	});

	test('Creator[alice].version(): => #ok - Version Number', async () => {
		actor_creator.setIdentity(alice);

		const version_num = await actor_creator.version();
		await actor_creator.init();

		expect(version_num).toBe(3n);
	});
});
