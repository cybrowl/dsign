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

		const creator_canister_id = await actor_username_registry.init();
		const creator_principal = Principal.fromText(creator_canister_id);
		actor_creator = pic.createActor(idlFactoryCreator, creator_principal);

		await actor_creator.init();
	});

	test('UsernameRegistry[link].version(): => #ok - Version Number', async () => {
		const version_num = await actor_username_registry.version();

		expect(version_num).toBe(4n);
	});

	test('UsernameRegistry[alice].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(alice);

		const { ok: username, err: error } = await actor_username_registry.create_profile('alice');
		expect(error).toBeUndefined();
		expect(username).toBeDefined();

		const { ok: username_info, err: info_error } =
			await actor_username_registry.get_info_by_username(username);
		expect(info_error).toBeUndefined();
		expect(username_info).toBeDefined();
		expect(username_info.username).toBe('alice');
	});

	test('UsernameRegistry[link].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(link);

		const { ok: username, err: error } = await actor_username_registry.create_profile('link');
		expect(error).toBeUndefined();
		expect(username).toBeDefined();

		const { ok: username_info, err: info_error } =
			await actor_username_registry.get_info_by_username(username);
		expect(info_error).toBeUndefined();
		expect(username_info).toBeDefined();
		expect(username_info.username).toBe('link');
	});

	test('Creator[alice].version(): => #ok - Version Number', async () => {
		actor_creator.setIdentity(alice);

		const version_num = await actor_creator.version();

		expect(version_num).toBe(3n);
	});

	test('Creator[alice].create_project(): with valid args => #ok - Project for Alice', async () => {
		const { ok: project, err: projectError } = await actor_creator.create_project({
			name: 'Alice Project',
			description: ['Project for Alice']
		});

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();
		expect(project.name).toBe('Alice Project');
		expect(project.description).toEqual(['Project for Alice']);
	});

	test('Creator[link].create_project(): with valid args => #ok - ProjectPublic', async () => {
		actor_creator.setIdentity(link);

		const { ok: project, err: projectError } = await actor_creator.create_project({
			name: 'Project Link',
			description: ['link project']
		});

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();
		expect(project.name).toBe('Project Link');
		expect(project.description).toEqual(['link project']);
	});
});
