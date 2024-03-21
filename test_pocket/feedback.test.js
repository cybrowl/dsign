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

describe('Feedback Integration Tests', async () => {
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
			arg: IDL.encode(initFSM({ IDL }), [true, '8080'])
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

	test('UsernameRegistry[james].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(james);
		const { ok: username, err: error } = await actor_username_registry.create_profile('james');
		expect(error).toBeUndefined();
		expect(username).toBeDefined();

		const { ok: username_info, err: info_error } =
			await actor_username_registry.get_info_by_username(username);
		expect(info_error).toBeUndefined();
		expect(username_info).toBeDefined();
		expect(username_info.username).toBe('james');
	});

	test('UsernameRegistry[daphne].create_profile(): with valid username => #ok - Username and Info', async () => {
		actor_username_registry.setIdentity(daphne);
		const { ok: username, err: error } = await actor_username_registry.create_profile('daphne');
		expect(error).toBeUndefined();
		expect(username).toBeDefined();

		const { ok: username_info, err: info_error } =
			await actor_username_registry.get_info_by_username(username);
		expect(info_error).toBeUndefined();
		expect(username_info).toBeDefined();
		expect(username_info.username).toBe('daphne');
	});

	test('Creator[james].create_project(): with valid args => #ok - Project for James', async () => {
		actor_creator.setIdentity(james);
		const { ok: project, err: projectError } = await actor_creator.create_project({
			name: 'James Project',
			description: ['Project for James']
		});

		james_projects.one = project;

		expect(projectError).toBeUndefined();
		expect(project).toBeTruthy();
		expect(project.name).toBe('James Project');
		expect(project.description).toEqual(['Project for James']);
	});

	test('Creator[james].create_snap(): with valid project_id, name, images, and img_location => #ok - SnapPublic', async () => {
		actor_file_storage.setIdentity(james);
		const file_storage_lib = new FileStorage(actor_file_storage);

		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_lib.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		actor_creator.setIdentity(james);
		const { ok: snap } = await actor_creator.create_snap({
			project_id: james_projects.one.id,
			name: 'First Snap',
			tags: [],
			design_file: [],
			image_cover_location: 0,
			images: [file]
		});

		james_snaps.one = snap;

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

	test('FeedbackTopic[daphne].create_feedback_topic(): with valid args => #ok - Feedback Topic for Daphne', async () => {
		actor_creator.setIdentity(daphne);
		const { ok: feedbackTopic, err: feedbackTopicError } =
			await actor_creator.create_feedback_topic({
				project_id: james_snaps.one.project_id,
				snap_id: james_snaps.one.id
			});

		expect(feedbackTopicError).toBeUndefined();
		expect(feedbackTopic).toBeTruthy();
		expect(feedbackTopic.design_file).toEqual([]);
		expect(feedbackTopic.messages).toHaveLength(1);
		expect(feedbackTopic.messages[0].content).toBe(
			'Give feedback, ask a question, or just leave a note.'
		);
		expect(feedbackTopic.messages[0].username).toBe('Jinx-Bot');
		expect(feedbackTopic.snap_name).toBe('First Snap');
	});

	test('Creator[daphne].add_file_to_topic(): with valid file => #ok - Topic', async () => {
		actor_file_storage.setIdentity(daphne);
		const file_storage_lib = new FileStorage(actor_file_storage);

		const fileObject = createFileObject(path.join(__dirname, 'figma_files', '5mb_components.fig'));
		const { ok: file } = await file_storage_lib.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		actor_creator.setIdentity(daphne);
		const { ok: topic, err: topicError } = await actor_creator.add_file_to_topic({
			project_id: james_projects.one.id,
			snap_id: james_snaps.one.id,
			message: [],
			design_file: [file]
		});

		const design_file_id = topic.design_file[0].id;

		const { ok: retrieved_file } = await file_storage_lib.get_file(design_file_id);

		console.log('owner: ', retrieved_file.owner);

		expect(topic).toBeDefined();
		expect(topicError).toBeUndefined();
		expect(topic.design_file).toBeInstanceOf(Array);
		expect(topic.design_file).toHaveLength(1);

		const designFile = topic.design_file[0];
		expect(designFile.name).toBe('5mb_components.fig');
		expect(designFile.chunks_size).toBe(3n);
		expect(designFile.content_size).toBe(4473449n);
		expect(designFile.content_type).toBe('application/octet-stream');
		expect(designFile.content_encoding).toBeInstanceOf(Object);
	});

	test('Creator[james].get_project(): with valid project_id => #ok - ProjectPublic with design file in topics', async () => {
		actor_creator.setIdentity(james);
		const { ok: projectPublic, err: error } = await actor_creator.get_project(
			james_projects.one.id
		);

		expect(error).toBeUndefined();
		expect(projectPublic).toBeDefined();
		expect(projectPublic.name).toBe('James Project');
		expect(projectPublic.description).toEqual(['Project for James']);

		// Check that the design file is included in the topics
		expect(projectPublic.feedback.topics).toHaveLength(1);
		expect(projectPublic.feedback.topics[0]).toBeInstanceOf(Array);

		expect(projectPublic.feedback.topics[0][0].design_file).toHaveLength(1);
		expect(projectPublic.feedback.topics[0][0].design_file[0].name).toBe('5mb_components.fig');
	});

	test('FileStorage[james].get_file(): with valid file_id => #ok - Check File owner', async () => {
		actor_file_storage.setIdentity(james);
		const file_storage_lib = new FileStorage(actor_file_storage);

		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_lib.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: retrievedFile, err: fileError } = await file_storage_lib.get_file(file.id);

		expect(fileError).toBeUndefined();
		expect(retrievedFile).toBeDefined();
		expect(retrievedFile.owner).toBe(james.getPrincipal().toString());
		expect(retrievedFile.id).toMatch(/[0-9A-F]{24}/i);
		expect(retrievedFile.url).toMatch(/^https:\/\/[a-z0-9-]+\.raw\.icp0\.io\/file\/[0-9A-F]{24}/i);
		expect(retrievedFile.created).toBeGreaterThan(0n);
		expect(retrievedFile.content).toBeInstanceOf(Array);
		expect(retrievedFile.owner).toMatch(/[a-z0-9-]{5,63}/i);
		expect(retrievedFile.chunks_size).toBeGreaterThan(0n);
		expect(retrievedFile.canister_id).toMatch(/[a-z0-9-]{5,63}/i);
		expect(retrievedFile.content_size).toBeGreaterThan(0n);
		expect(retrievedFile.content_type).toMatch(/^[a-z0-9\/-]+$/i);
		expect(retrievedFile.filename).toMatch(/^.+\..+$/);
		expect(retrievedFile.content_encoding).toEqual(expect.any(Object));
	});

	test('Creator[james].update_snap_with_file_change(): with valid snap_id and file change => #ok - Updated SnapPublic', async () => {
		//TODO: the strucure of the code needs to change for this testing to be done
	});

	test('Creator[james].get_snap(): with valid snap_id => #ok - SnapPublic', async () => {
		//TODO: the strucure of the code needs to change for this testing to be done
	});

	test('Creator[james].get_project(): with valid project_id => #ok - ProjectPublic without design file in topics', async () => {
		//TODO: the strucure of the code needs to change for this testing to be done
	});
});
