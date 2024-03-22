import { Principal } from '@dfinity/principal';
import { PocketIc, createIdentity } from '@hadronous/pic';
import { resolve } from 'node:path';
import path from 'path';
import { describe, test, expect, beforeAll } from 'vitest';
import { createFileObject } from '../test_e2e/libs/file.js';
import { FileStorage } from '../src/ui/utils/file_storage.js';
import { IDL } from '@dfinity/candid';

import {
	_SERVICE,
	idlFactory as idlFactoryUsernameRegistry
} from '../.dfx/local/canisters/username_registry/service.did.js';

import {
	_SERVICE,
	idlFactory as idlFactoryCreator
} from '../.dfx/local/canisters/creator/service.did.js';

import {
	_SERVICE,
	idlFactory as idlFactoryFSManager,
	init as initFSM
} from '../.dfx/local/canisters/file_scaling_manager/service.did.js';

import {
	_SERVICE,
	idlFactory as idlFactoryFileStorage,
	init as initFileStorage
} from '../.dfx/local/canisters/file_storage/service.did.js';

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

const WASM_PATH_FS_MANAGER = resolve(
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

describe('Feedback', async () => {
	const pic = await PocketIc.create();

	let actor_username_registry = {};
	let actor_creator = {};
	let actor_file_scaling_manager = {};
	let file_storage_actor_lib = {};

	const alice = createIdentity('alice_pass');
	const link = createIdentity('link_pass');

	let alice_projects = {};
	let alice_snaps = {};

	beforeAll(async () => {
		const setup_args_username_registry = {
			idlFactory: idlFactoryUsernameRegistry,
			wasm: WASM_PATH_USERNAME_REGISTRY
		};

		const setup_args_file_scaling_manager = {
			idlFactory: idlFactoryFSManager,
			wasm: WASM_PATH_FS_MANAGER,
			arg: IDL.encode(initFSM({ IDL }), [true, '8080', 20])
		};

		const fixture_username_registry = await pic.setupCanister(setup_args_username_registry);
		const fixture_file_scaling_manager = await pic.setupCanister(setup_args_file_scaling_manager);

		actor_username_registry = fixture_username_registry.actor;
		actor_file_scaling_manager = fixture_file_scaling_manager.actor;

		//DELETE PROFILES TO BE USED
		actor_username_registry.setIdentity(alice);
		await actor_username_registry.delete_profile();

		actor_username_registry.setIdentity(link);
		await actor_username_registry.delete_profile();

		const creator_cid = await actor_username_registry.init();
		const file_storage_cid = await actor_file_scaling_manager.init();

		const creator_principal = Principal.fromText(creator_cid);
		actor_creator = pic.createActor(idlFactoryCreator, creator_principal);

		await actor_creator.init();

		const file_storage_actor = pic.createActor(
			idlFactoryFileStorage,
			Principal.fromText(file_storage_cid)
		);

		file_storage_actor_lib.alice = new FileStorage(file_storage_actor);
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

	test('Creator[alice].create_project(): with valid args => #ok - Project for Alice', async () => {
		actor_creator.setIdentity(alice);

		const { ok: project, err: projectError } = await actor_creator.create_project({
			name: 'Alice Project',
			description: ['Project for Alice']
		});

		alice_projects.one = project;

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();
		expect(project.name).toBe('Alice Project');
		expect(project.description).toEqual(['Project for Alice']);
	});

	test('Creator[alice].get_project(): with existing project => #ok - Retrieve Project', async () => {
		actor_creator.setIdentity(alice);

		const projectId = alice_projects.one.id;

		const { ok: project, err: projectError } = await actor_creator.get_project(projectId);

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();
		expect(project.name).toBe('Alice Project');
		expect(project.description).toEqual(['Project for Alice']);
	});

	test('Creator[alice].create_snap(): with valid project_id, name, images, and img_location => #ok - SnapPublic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_actor_lib.alice.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: snap } = await actor_creator.create_snap({
			project_id: alice_projects.one.id,
			name: 'First Snap',
			tags: [],
			design_file: [],
			image_cover_location: 0,
			images: [file]
		});

		alice_snaps.one = snap;

		// Assertions for snap properties
		expect(snap.name).toBe('First Snap');
		expect(snap.tags).toEqual([]);
		expect(snap.images).toHaveLength(1);

		// Assertions for the uploaded image
		const uploadedImage = snap.images[0];
		expect(uploadedImage.name).toBe('3mb_japan.jpg');
		expect(uploadedImage.content_type).toBe('image/jpeg');
		expect(uploadedImage.content_size).toBeGreaterThan(0);
		expect(uploadedImage.url.startsWith('https://')).toBe(true);
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

	test('Creator[alice].get_project(): verify project contains the snap', async () => {
		actor_creator.setIdentity(alice);

		const projectId = alice_projects.one.id;
		const snapId = alice_snaps.one.id;

		const { ok: project, err: projectError } = await actor_creator.get_project(projectId);

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();

		const snapExists = project.snaps.some((snap) => snap.id === snapId);

		expect(snapExists).toBe(true);
	});

	test('Creator[link].get_profile_by_username(): verify profile before adding favorite', async () => {
		actor_creator.setIdentity(link);

		const username = 'link';
		const { ok: initial_profile_result, err: initial_error } =
			await actor_creator.get_profile_by_username(username);

		expect(initial_error).toBeUndefined();
		expect(initial_profile_result).toBeDefined();
		expect(initial_profile_result.favorites).not.toContainEqual({
			project_id: alice_projects.one.id,
			canister_id: alice_projects.one.canister_id
		});
	});

	test('Creator[link].save_project_as_fav(): with valid project_id and canister_id => #ok - Project Saved as Favorite', async () => {
		actor_creator.setIdentity(link);

		const project_id = alice_projects.one.id;
		const creator_canister_id = alice_projects.one.canister_id;

		const { ok: is_favorited, err: error } = await actor_creator.save_project_as_fav(
			project_id,
			creator_canister_id
		);

		expect(error).toBeUndefined();
		expect(is_favorited).toBe(true);
	});

	test('Creator[link].get_profile_by_username(): verify favorite is there', async () => {
		actor_creator.setIdentity(link);

		const username = 'link';
		const { ok: profile_result, err: error } =
			await actor_creator.get_profile_by_username(username);

		expect(error).toBeUndefined();
		expect(profile_result).toBeDefined();
		expect(profile_result.favorites).toContainEqual({
			id: alice_projects.one.id,
			created: alice_projects.one.created,
			username: 'alice',
			metrics: expect.any(Object),
			owner: expect.any(Array),
			name: 'Alice Project',
			canister_id: alice_projects.one.canister_id,
			is_owner: false,
			description: expect.any(Array),
			feedback: expect.any(Object),
			snaps: expect.any(Array)
		});
	});

	test('Creator[link].save_project_as_fav(): adding the same project again should not duplicate it in favorites', async () => {
		actor_creator.setIdentity(link);

		const project_id = alice_projects.one.id;
		const creator_canister_id = alice_projects.one.canister_id;

		// Attempt to favorite the project a second time
		const { ok: is_favorited_again, err: error_again } = await actor_creator.save_project_as_fav(
			project_id,
			creator_canister_id
		);

		expect(error_again).toEqual({ ProjectExists: true });
		expect(is_favorited_again).toBeUndefined();

		// Retrieve the profile to verify the project is not duplicated in favorites
		const username = 'link';
		const { ok: profile_result_after, err: error_after } =
			await actor_creator.get_profile_by_username(username);

		expect(error_after).toBeUndefined();
		expect(profile_result_after).toBeDefined();

		// Count how many times the project appears in the favorites
		const favoriteCount = profile_result_after.favorites.reduce((count, favorite) => {
			return favorite.id === project_id && favorite.canister_id === creator_canister_id
				? count + 1
				: count;
		}, 0);

		// The project should only appear once in the favorites
		expect(favoriteCount).toBe(1);
	});

	test('Creator[link].delete_project_from_favs(): removing a project from favorites => #ok - Project Removed from Favorites', async () => {
		actor_creator.setIdentity(link);

		const project_id = alice_projects.one.id;

		// Remove the project from favorites
		const { ok: is_removed, err: remove_error } =
			await actor_creator.delete_project_from_favs(project_id);

		expect(remove_error).toBeUndefined();
		expect(is_removed).toBe(true);

		// Retrieve the profile to verify the project is removed from favorites
		const username = 'link';
		const { ok: profile_result_after_removal, err: error_after_removal } =
			await actor_creator.get_profile_by_username(username);

		expect(error_after_removal).toBeUndefined();
		expect(profile_result_after_removal).toBeDefined();

		// Verify the project is not present in the favorites after removal
		const favoriteExists = profile_result_after_removal.favorites.some(
			(favorite) => favorite.id === project_id
		);
		expect(favoriteExists).toBe(false);
	});
});
