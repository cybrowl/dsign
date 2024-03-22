import path from 'path';
import { describe, test, expect, beforeAll } from 'vitest';
import { PocketIc, createIdentity } from '@hadronous/pic';
import { Principal } from '@dfinity/principal';
import { createFileObject } from '../test_e2e/libs/file.js';
import { FileStorage } from '../src/ui/utils/file_storage.js';
import { IDL } from '@dfinity/candid';

import { idlFactory as idl_factory_username_registry } from '../.dfx/local/canisters/username_registry/service.did.js';

import { idlFactory as idl_factory_creator } from '../.dfx/local/canisters/creator/service.did.js';

import {
	_SERVICE,
	init as initFSM
} from '../.dfx/local/canisters/file_scaling_manager/service.did.js';

import { idlFactory as idlFactoryFileStorage } from '../.dfx/local/canisters/file_storage/service.did.js';

const WASM_PATH_USERNAME_REGISTRY = path.resolve(
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

const WASM_PATH_FS_MANAGER = path.resolve(
	__dirname,
	'..',
	'..',
	'dsign',
	'.dfx',
	'local',
	'canisters',
	'file_scaling_manager',
	'file_scaling_manager.wasm'
);

import {
	idlFactory as idlFactoryFSManager,
	init as initFSM
} from '../.dfx/local/canisters/file_scaling_manager/service.did.js';

import {
	idlFactory as idlFactoryFileStorage,
	init as initFileStorage
} from '../.dfx/local/canisters/file_storage/service.did.js';

describe('Scaling Creator', async () => {
	const pic = await PocketIc.create();

	let actor_username_registry = {};
	let actor_creator = {};
	let actor_file_scaling_manager = {};
	let actor_file_storage = {};

	const daphne = createIdentity('daphne_pass');
	const james = createIdentity('james_pass');

	let daphne_projects = {};
	let james_projects = {};
	let james_snaps = {};

	beforeAll(async () => {
		// Username Registry
		const setup_args_username_registry = {
			idlFactory: idl_factory_username_registry,
			wasm: WASM_PATH_USERNAME_REGISTRY
		};
		const fixture_username_registry = await pic.setupCanister(setup_args_username_registry);
		actor_username_registry = fixture_username_registry.actor;

		// Creator
		const creator_cid = await actor_username_registry.init();
		const creator_principal = Principal.fromText(creator_cid);
		actor_creator = pic.createActor(idl_factory_creator, creator_principal);
		await actor_creator.init();

		// File Storage
		const setup_args_file_scaling_manager = {
			idlFactory: idlFactoryFSManager,
			wasm: WASM_PATH_FS_MANAGER,
			arg: IDL.encode(initFSM({ IDL }), [true, '8080', 20])
		};

		const fixture_file_scaling_manager = await pic.setupCanister(setup_args_file_scaling_manager);
		actor_file_scaling_manager = fixture_file_scaling_manager.actor;
		const file_storage_cid = await actor_file_scaling_manager.init();
		actor_file_storage = pic.createActor(
			idlFactoryFileStorage,
			Principal.fromText(file_storage_cid)
		);

		//DELETE PROFILES TO BE USED
		actor_username_registry.setIdentity(daphne);
		await actor_username_registry.delete_profile();

		actor_username_registry.setIdentity(james);
		await actor_username_registry.delete_profile();
	});

	test('UsernameRegistry.create_bulk_profiles: create 100 profiles with random names', async () => {
		for (let i = 0; i < 100; i++) {
			const randomUsername = `user${Math.random().toString(36).substring(2, 15)}`.toLowerCase();

			actor_username_registry.setIdentity(createIdentity(`${randomUsername}_pass`));

			const { ok: username, err: error } =
				await actor_username_registry.create_profile(randomUsername);
			expect(error).toBeUndefined();
			expect(username).toBeDefined();
			expect(username).toBe(randomUsername);

			const { ok: username_info, err: info_error } =
				await actor_username_registry.get_info_by_username(username);
			expect(info_error).toBeUndefined();
			expect(username_info).toBeDefined();
			expect(username_info.username).toBe(randomUsername);
		}
	});

	test('UsernameRegistry[daphne].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(daphne);
		const { ok: username, err: error } = await actor_username_registry.create_profile('daphne');

		expect(error).toBeUndefined();
		expect(username).toBeDefined();
		expect(username).toEqual('daphne');
	});

	test('UsernameRegistry[james].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(james);
		const { ok: username } = await actor_username_registry.create_profile('james');

		expect(username).toBeDefined();

		const { ok: username_info_daphne } =
			await actor_username_registry.get_info_by_username('daphne');
		const { ok: username_info_james } = await actor_username_registry.get_info();

		expect(username_info_daphne).toBeDefined();
		expect(username_info_james).toBeDefined();
		expect(username_info_daphne.username).toEqual('daphne');
		expect(username_info_james.username).toEqual('james');
		expect(username_info_daphne.canister_id).toBeDefined();
		expect(username_info_james.canister_id).toBeDefined();
		expect(username_info_daphne.canister_id).not.toEqual(username_info_james.canister_id);
		expect(username_info_daphne.canister_id).not.toEqual(username_info_james.canister_id);
	});

	test('UsernameRegistry.create_bulk_profiles: create 1_000 profiles with random names', async () => {
		for (let i = 0; i < 1000; i++) {
			const randomUsername = `user${Math.random().toString(36).substring(2, 15)}`.toLowerCase();

			actor_username_registry.setIdentity(createIdentity(`${randomUsername}_pass`));

			const { ok: username, err: error } =
				await actor_username_registry.create_profile(randomUsername);
			expect(error).toBeUndefined();
			expect(username).toBeDefined();
			expect(username).toBe(randomUsername);

			const { ok: username_info, err: info_error } =
				await actor_username_registry.get_info_by_username(username);
			expect(info_error).toBeUndefined();
			expect(username_info).toBeDefined();
			expect(username_info.username).toBe(randomUsername);
		}
	});

	test('UsernameRegistry.get_registry: should return a registry with length 11', async () => {
		actor_username_registry.setIdentity(daphne);
		const registry = await actor_username_registry.get_registry();

		expect(registry).toBeDefined();
		expect(registry.length).toBe(11);
	});
});
