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
			arg: IDL.encode(initFSM({ IDL }), [true, '8080', 20])
		};

		const fixture_file_scaling_manager = await pic.setupCanister(setup_args_file_scaling_manager);
		actor_file_scaling_manager = fixture_file_scaling_manager.actor;
		await actor_file_scaling_manager.init();

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

	test('FileStorage[daphne].store(): storing 2 video files ~ 27MB => #ok - Files', async () => {
		const file_storage_cid = await actor_file_scaling_manager.init();

		const actor_file_storage = pic.createActor(
			idlFactoryFileStorage,
			Principal.fromText(file_storage_cid)
		);

		actor_file_storage.setIdentity(daphne);
		const file_storage_lib = new FileStorage(actor_file_storage);

		const fileObjects = [];
		for (let i = 0; i < 2; i++) {
			fileObjects.push(createFileObject(path.join(__dirname, 'videos', 'delta_city.mp4')));
		}

		const storePromises = fileObjects.map((fileObject) =>
			file_storage_lib.store(fileObject.content, {
				filename: fileObject.name,
				content_type: fileObject.type
			})
		);

		const results = await Promise.all(storePromises);
		results.forEach((result, index) => {
			const { ok: file } = result;
			expect(file).toBeDefined();
		});
	});
});
