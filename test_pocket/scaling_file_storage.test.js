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

describe('Scaling File Storage', async () => {
	const pic = await PocketIc.create();

	let actor_username_registry = {};
	let actor_file_scaling_manager = {};

	const daphne = createIdentity('daphne_pass');
	const james = createIdentity('james_pass');

	beforeAll(async () => {
		// Username Registry
		const setup_args_username_registry = {
			idlFactory: idl_factory_username_registry,
			wasm: WASM_PATH_USERNAME_REGISTRY
		};
		const fixture_username_registry = await pic.setupCanister(setup_args_username_registry);
		actor_username_registry = fixture_username_registry.actor;
		await actor_username_registry.init();

		// File Storage
		const setup_args_file_scaling_manager = {
			idlFactory: idlFactoryFSManager,
			wasm: WASM_PATH_FS_MANAGER,
			arg: IDL.encode(initFSM({ IDL }), [true, '8080', 10])
		};

		const fixture_file_scaling_manager = await pic.setupCanister(setup_args_file_scaling_manager);
		actor_file_scaling_manager = fixture_file_scaling_manager.actor;

		//DELETE PROFILES TO BE USED
		actor_username_registry.setIdentity(daphne);
		await actor_username_registry.delete_profile();

		actor_username_registry.setIdentity(james);
		await actor_username_registry.delete_profile();
	});

	test('UsernameRegistry[daphne].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(daphne);
		const { ok: username, err: error } = await actor_username_registry.create_profile('daphne');

		expect(username).toEqual('daphne');
	});

	test('UsernameRegistry[james].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(james);
		const { ok: username } = await actor_username_registry.create_profile('james');

		expect(username).toEqual('james');
	});

	test('FileStorage[daphne].store(): storing 1 video file 13MB file scaling of 3 file_storage canisters => #ok - File', async () => {
		const file_storage_cid = await actor_file_scaling_manager.init();

		const registry_size_1 = await actor_file_scaling_manager.get_file_storage_registry_size();
		expect(registry_size_1).toEqual(1n);

		const actor_file_storage = pic.createActor(
			idlFactoryFileStorage,
			Principal.fromText(file_storage_cid)
		);

		actor_file_storage.setIdentity(daphne);
		const file_storage_lib = new FileStorage(actor_file_storage);
		const fileObject = createFileObject(path.join(__dirname, 'videos', 'delta_city.mp4'));

		const { ok: file } = await file_storage_lib.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});
		expect(file).toBeDefined();

		await actor_file_scaling_manager.check_canister_is_full_public();

		const registry_size_2 = await actor_file_scaling_manager.get_file_storage_registry_size();
		expect(registry_size_2).toEqual(2n);

		const registry = await actor_file_scaling_manager.get_file_storage_registry();

		const actor_file_storage_2 = pic.createActor(
			idlFactoryFileStorage,
			Principal.fromText(registry[1].id)
		);

		actor_file_storage.setIdentity(daphne);
		const file_storage_lib_2 = new FileStorage(actor_file_storage_2);

		const { ok: file_2 } = await file_storage_lib_2.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});
		expect(file_2).toBeDefined();

		await actor_file_scaling_manager.check_canister_is_full_public();

		const registry_size_3 = await actor_file_scaling_manager.get_file_storage_registry_size();
		expect(registry_size_3).toEqual(3n);
	});
});
