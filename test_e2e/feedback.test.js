import { describe, test, expect, beforeAll } from 'vitest';
import { config } from 'dotenv';
import path from 'path';
import { canister_ids, getInterfaces } from '../config/actor_refs';
import { parseIdentity } from './actor_identity.cjs';
import { getActor } from './actor.cjs';
import { createFileObject } from './libs/file';
import { requestResource } from './libs/http.cjs';
import { getRandomSubsetIds } from './libs/images';
import { FileStorage } from '../src/ui/utils/file_storage';

// Configure environment variables
config();

// Identities
let jt_identity = parseIdentity(process.env.JT_IDENTITY);
let wilson_identity = parseIdentity(process.env.WILSON_IDENTITY);
let anonymous_identity = null;

let interfaces = {};

let username_registry_actor = {};
let file_scaling_manager_actor = {};
let file_storage_actor_lib = {};
let creator_actor_jt = {};
let creator_actor_wilson = {};

let jt_project_a = {};
let jt_snap_a = {};
let jt_snap_b = {};

// Helper function to mimic the File Web API object in Node.js

describe('Feedback', () => {
	beforeAll(async () => {
		interfaces = await getInterfaces();

		// Setup Username Registry Actors
		username_registry_actor.jt = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			jt_identity
		);
		username_registry_actor.wilson = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			wilson_identity
		);
		username_registry_actor.anonymous = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			anonymous_identity
		);

		// Setup File Scaling Manager Actors
		file_scaling_manager_actor.jt = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			jt_identity
		);
		file_scaling_manager_actor.wilson = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			wilson_identity
		);
		file_scaling_manager_actor.anonymous = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			anonymous_identity
		);

		const fs_canister_id = await file_scaling_manager_actor.jt.get_current_canister_id();
		const file_storage_actor = await getActor(fs_canister_id, interfaces.file_storage, jt_identity);

		file_storage_actor_lib.jt = new FileStorage(file_storage_actor);

		//DELETE PROFILES TO BE USED
		await username_registry_actor.jt.delete_profile();
		await username_registry_actor.wilson.delete_profile();
	});

	test('UsernameRegistry[jt].create_profile(): with valid username => #ok - Username', async () => {
		// Setup: Ensure there's a profile to delete
		const { ok: username, err: error } = await username_registry_actor.jt.create_profile('jt');

		const { ok: username_info } = await username_registry_actor.jt.get_info_by_username(username);

		creator_actor_jt = await getActor(username_info.canister_id, interfaces.creator, jt_identity);

		expect(username.length).toBeGreaterThan(1);
	});

	test('UsernameRegistry[wilson].create_profile(): with valid username => #ok - Username', async () => {
		const { ok: username } = await username_registry_actor.wilson.create_profile('wilson');
		const { ok: username_info } =
			await username_registry_actor.wilson.get_info_by_username(username);

		creator_actor_wilson = await getActor(
			username_info.canister_id,
			interfaces.creator,
			wilson_identity
		);

		expect(username.length).toBeGreaterThan(2);
	});

	test('Creator[jt].create_project(): with valid args => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_jt.create_project({
			name: 'Project One',
			description: ['first project']
		});

		jt_project_a = project;

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[jt].create_snap(): with valid project_id, name, images, and img_location => #ok - SnapPublic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_actor_lib.jt.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: snap } = await creator_actor_jt.create_snap({
			project_id: jt_project_a.id,
			name: 'First Snap',
			tags: [],
			design_file: [],
			image_cover_location: 0,
			images: [file]
		});

		if (snap) {
			jt_snap_a = snap;

			// Assertions for snap properties
			expect(snap.name).toBe('First Snap');
			expect(snap.tags).toEqual([]);
			expect(snap.images).toHaveLength(1);

			// Assertions for the uploaded image
			const uploadedImage = snap.images[0];
			expect(uploadedImage.name).toBe('3mb_japan.jpg');
			expect(uploadedImage.content_type).toBe('image/jpeg');
			expect(uploadedImage.content_size).toBeGreaterThan(0);
			expect(uploadedImage.url.startsWith('http://')).toBe(true);
		}
	});

	test('Creator[jt].create_snap(): with valid project_id, name, images, and img_location => #ok - SnapPublic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_actor_lib.jt.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: snap } = await creator_actor_jt.create_snap({
			project_id: jt_project_a.id,
			name: 'Second Snap',
			tags: [],
			design_file: [],
			image_cover_location: 0,
			images: [file]
		});

		if (snap) {
			jt_snap_b = snap;

			// Assertions for snap properties
			expect(snap.name).toBe('Second Snap');
			expect(snap.tags).toEqual([]);
			expect(snap.images).toHaveLength(1);

			// Assertions for the uploaded image
			const uploadedImage = snap.images[0];
			expect(uploadedImage.name).toBe('3mb_japan.jpg');
			expect(uploadedImage.content_type).toBe('image/jpeg');
			expect(uploadedImage.content_size).toBeGreaterThan(0);
			expect(uploadedImage.url.startsWith('http://')).toBe(true);
		}
	});

	test('Creator[jt].create_feedback_topic(): with valid args => #ok - Topic', async () => {
		const response = await creator_actor_jt.create_feedback_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_a.id
		});

		expect(response.ok).toBeTruthy();

		const topic = response.ok;

		expect(topic).toHaveProperty('id', jt_snap_a.id);
		expect(topic).toHaveProperty('snap_name', 'First Snap');
		expect(topic).toHaveProperty('design_file', []);
		expect(topic.messages).toHaveLength(1);
		expect(topic.messages[0]).toMatchObject({
			content: 'Give feedback, ask a question, or just leave a note.',
			username: 'Jinx-Bot'
		});
	});

	test('Creator[jt].create_feedback_topic(): with valid args => #ok - Topic', async () => {
		const response = await creator_actor_jt.create_feedback_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_b.id
		});

		expect(response.ok).toBeTruthy();

		const topic = response.ok;

		expect(topic).toHaveProperty('id', jt_snap_b.id);
		expect(topic).toHaveProperty('snap_name', 'Second Snap');
		expect(topic).toHaveProperty('design_file', []);
		expect(topic.messages).toHaveLength(1);
		expect(topic.messages[0]).toMatchObject({
			content: 'Give feedback, ask a question, or just leave a note.',
			username: 'Jinx-Bot'
		});
	});

	test('Creator[jt].get_project(): with valid id => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_jt.get_project(jt_project_a.id);

		expect(project.feedback).toBeTruthy();
		expect(project.feedback.topics).toBeInstanceOf(Array);
		expect(project.feedback.topics[0].length).toBeGreaterThan(1);
	});

	test('Creator[jt].add_message_to_topic(): with valid message => #ok - Topic', async () => {
		const response = await creator_actor_jt.add_message_to_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_a.id,
			message: ['Great work on this design!'],
			design_file: []
		});

		expect(response.ok).toBeTruthy();

		const topic = response.ok;

		expect(topic.messages).toHaveLength(2);
		expect(topic.messages).toContainEqual(
			expect.objectContaining({
				content: 'Great work on this design!',
				username: 'jt'
			})
		);
	});

	test('Creator[jt].get_project(): with valid id => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_jt.get_project(jt_project_a.id);

		expect(project).toBeTruthy();
		expect(project.id).toBe(jt_project_a.id);
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
		expect(project.snaps).toBeInstanceOf(Array);

		expect(project.feedback).toBeTruthy();
		expect(project.feedback.topics).toBeInstanceOf(Array);
		expect(project.feedback.topics[0].length).toBeGreaterThan(0);

		expect(project.feedback.topics[0][0]).toMatchObject({
			snap_name: expect.any(String)
		});
	});

	test('Creator[jt].add_file_to_topic(): with valid file => #ok - Topic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'figma_files', '5mb_components.fig'));
		const { ok: file } = await file_storage_actor_lib.jt.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: topic } = await creator_actor_jt.add_file_to_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_a.id,
			message: [],
			design_file: [file]
		});

		expect(topic).toBeTruthy();

		expect(topic.design_file).toHaveLength(1);
		const designFile = topic.design_file[0];

		expect(typeof designFile.created).toBe('bigint');
		expect(typeof designFile.chunks_size).toBe('bigint');
		expect(typeof designFile.content_size).toBe('bigint');
		expect(designFile.content_type).toBe('application/octet-stream');
		expect(designFile.name).toBe('5mb_components.fig');
		expect(designFile.content_encoding).toBeInstanceOf(Object);

		expect(topic.messages).toHaveLength(2);
		expect(topic.messages[0].content).toBe('Give feedback, ask a question, or just leave a note.');
		expect(topic.messages[0].username).toBe('Jinx-Bot');
		expect(topic.messages[1].content).toBe('Great work on this design!');
		expect(topic.messages[1].username).toBe('jt');
	});

	test('Creator[jt].delete_file_from_topic(): with valid owner of topic => #ok - Bool', async () => {
		const { ok: deleted_topic } = await creator_actor_jt.delete_file_from_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_a.id,
			message: [], // No message being added
			design_file: [] // No file being added
		});

		expect(deleted_topic).toBeTruthy();
	});

	test('Creator[jt].get_project(): verify file was deleted', async () => {
		const { ok: project } = await creator_actor_jt.get_project(jt_project_a.id);

		expect(project).toBeTruthy();
		expect(project.id).toBe(jt_project_a.id);
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
		expect(project.snaps).toBeInstanceOf(Array);

		expect(project.feedback).toBeTruthy();
		expect(project.feedback.topics[0]).toBeInstanceOf(Array);

		project.feedback.topics.forEach((topicArray) => {
			topicArray.forEach((topic) => {
				expect(topic.design_file).toBeInstanceOf(Array);
				expect(topic.design_file.length).toBe(0);
			});
		});
	});

	test('Creator[jt].delete_feedback_topic(): with valid id => #ok - Bool', async () => {
		const { ok: deleted_topic } = await creator_actor_jt.delete_feedback_topic({
			project_id: jt_project_a.id,
			snap_id: jt_snap_a.id,
			message: [], // No message being added
			design_file: [] // No file being added
		});

		expect(deleted_topic).toBeTruthy();
	});

	test('Creator[jt].get_project(): verify a specific topic was deleted', async () => {
		const { ok: project } = await creator_actor_jt.get_project(jt_project_a.id);

		expect(project).toBeTruthy();
		expect(project.id).toBe(jt_project_a.id);
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
		expect(project.snaps).toBeInstanceOf(Array);

		expect(project.feedback).toBeTruthy();
		expect(project.feedback.topics[0]).toBeInstanceOf(Array);

		const deletedTopicId = jt_snap_a.id;

		const isDeletedTopicPresent = project.feedback.topics.some((topicArray) =>
			topicArray.some((topic) => topic.id === deletedTopicId)
		);

		expect(isDeletedTopicPresent).toBeFalsy();
	});
});
