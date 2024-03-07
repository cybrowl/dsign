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
let nikola_identity = parseIdentity(process.env.NIKOLA_IDENTITY);
let linky_identity = parseIdentity(process.env.LINKY_IDENTITY);
let anonymous_identity = null;

let interfaces = {};

let username_registry_actor = {};
let file_scaling_manager_actor = {};
let file_storage_actor_lib = {};
let creator_actor_nikola = {};
let creator_actor_linky = {};

let nikola_project_a = {};
let nikola_snap_a = {};

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

		//DELETE PROFILES TO BE USED
		await username_registry_actor.nikola.delete_profile();
		await username_registry_actor.linky.delete_profile();
	});

	// Example Test: Check version number of UsernameRegistry[nikola]
	test('UsernameRegistry[nikola].version(): => #ok - Version Number', async () => {
		const version_num = await username_registry_actor.nikola.version();
		expect(version_num).toBe(1n);
	});

	test('UsernameRegistry[nikola].create_profile(): with valid username => #ok - Username', async () => {
		// Setup: Ensure there's a profile to delete
		const { ok: username } = await username_registry_actor.nikola.create_profile('nikola');
		const { ok: username_info } =
			await username_registry_actor.nikola.get_info_by_username(username);

		creator_actor_nikola = await getActor(
			username_info.canister_id,
			interfaces.creator,
			nikola_identity
		);

		expect(username.length).toBeGreaterThan(2);
	});

	test('UsernameRegistry[linky].create_profile(): with valid username => #ok - Username', async () => {
		const { ok: username } = await username_registry_actor.linky.create_profile('linky');
		const { ok: username_info } =
			await username_registry_actor.linky.get_info_by_username(username);

		creator_actor_linky = await getActor(
			username_info.canister_id,
			interfaces.creator,
			linky_identity
		);

		expect(username.length).toBeGreaterThan(2);
	});

	test('Creator[nikola].create_project(): with valid args => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_nikola.create_project({
			name: 'Project One',
			description: ['first project']
		});

		nikola_project_a = project;

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[nikola].create_snap(): with valid project_id, name, images, and img_location => #ok - SnapPublic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'images', 'size', '3mb_japan.jpg'));
		const { ok: file } = await file_storage_actor_lib.nikola.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: snap } = await creator_actor_nikola.create_snap({
			project_id: nikola_project_a.id,
			name: 'First Snap',
			tags: [],
			design_file: [],
			image_cover_location: 0,
			images: [file]
		});

		if (snap) {
			nikola_snap_a = snap;

			// Assertions for snap properties
			expect(snap.name).toBe('First Snap');
			expect(snap.tags).toEqual([]);
			expect(snap.images).toHaveLength(1);

			// Assertions for the uploaded image
			const uploadedImage = snap.images[0];
			expect(uploadedImage.filename).toBe('3mb_japan.jpg');
			expect(uploadedImage.content_type).toBe('image/jpeg');
			expect(uploadedImage.content_size).toBeGreaterThan(0);
			expect(uploadedImage.url.startsWith('http://')).toBe(true);
		}
	});

	test('Creator[nikola].get_snap(): with valid project_id => #ok - SnapPublic', async () => {
		const { ok: snap } = await creator_actor_nikola.get_snap(nikola_snap_a.id);
		// Assertions for snap properties

		if (snap) {
			expect(snap.name).toBe('First Snap');
			expect(snap.tags).toEqual([]);
			expect(snap.images).toHaveLength(1);

			// Assertions for the uploaded image and HTTP response
			const uploadedImage = snap.images[0];
			const img_http_response = await requestResource(uploadedImage.url);

			expect(img_http_response.statusCode).toBe(200);
			expect(uploadedImage.filename).toBe('3mb_japan.jpg');
			expect(uploadedImage.content_type).toBe('image/jpeg');
			expect(uploadedImage.content_size).toBeGreaterThan(0); // Adjust if it's BigInt and ensure compatibility
			expect(uploadedImage.url.startsWith('http://')).toBe(true);
		}
	});

	test('Creator[nikola].update_snap(): with valid name => #ok - SnapPublic', async () => {
		const { ok: snap } = await creator_actor_nikola.update_snap({
			id: nikola_snap_a.id,
			name: ['First Snap Updated'],
			design_file: [],
			image_cover_location: [],
			tags: [],
			images: []
		});

		if (snap) {
			nikola_snap_a = snap;

			expect(snap.name).toBe('First Snap Updated');
			expect(snap.tags).toEqual([]);
			expect(snap.images).toHaveLength(1);
		}
	});

	test('Creator[nikola].update_snap(): with valid tags => #ok - SnapPublic', async () => {
		const { ok: snap } = await creator_actor_nikola.update_snap({
			id: nikola_snap_a.id,
			name: [],
			design_file: [],
			image_cover_location: [],
			tags: [['ocean']],
			images: []
		});

		if (snap) {
			nikola_snap_a = snap;

			expect(snap.name).toBe('First Snap Updated');
			expect(snap.tags).toEqual(['ocean']);
			expect(snap.images).toHaveLength(1);
		}
	});

	test('Creator[nikola].update_snap(): with images & image_cover_location => #ok - SnapPublic', async () => {
		const filePaths = [
			path.join(__dirname, 'images', 'size', '3mb_japan.jpg'),
			path.join(__dirname, 'images', 'size', '1mb_motoko.png')
		];

		// Map over filePaths to create and store file objects in parallel
		const results = await Promise.all(
			filePaths.map(async (filePath) => {
				const fileObject = createFileObject(filePath);
				return file_storage_actor_lib.nikola.store(fileObject.content, {
					filename: fileObject.name,
					content_type: fileObject.type
				});
			})
		);

		// Extract the ok values from results
		const files = results.map((result) => result.ok);

		// Assert each file was stored successfully
		files.forEach((file) => {
			expect(file).toBeDefined();
		});

		const { ok: snap } = await creator_actor_nikola.update_snap({
			id: nikola_snap_a.id,
			name: [],
			design_file: [],
			image_cover_location: [1],
			tags: [['ocean']],
			images: [files]
		});

		if (snap) {
			nikola_snap_a = snap;

			expect(snap.name).toBe('First Snap Updated');
			expect(snap.tags).toEqual(['ocean']);
			expect(snap.images).toHaveLength(2);
			expect(snap.image_cover_location).toBe(1);
		}
	});

	test('Creator[nikola].delete_snap_images(): with valid images => #ok - Bool', async () => {
		if (nikola_snap_a.images) {
			const snap_images_ids = getRandomSubsetIds(nikola_snap_a.images, 1);

			const { ok: images_deleted } = await creator_actor_nikola.delete_snap_images(
				nikola_snap_a.id,
				snap_images_ids
			);

			expect(images_deleted).toBe(true);

			const { ok: snap } = await creator_actor_nikola.get_snap(nikola_snap_a.id);

			if (snap) {
				nikola_snap_a = snap;

				expect(snap.name).toBe('First Snap Updated');
				expect(snap.tags).toEqual(['ocean']);
				expect(snap.images).toHaveLength(1);
				expect(snap.design_file).toHaveLength(0);
			}
		}
	});

	test('Creator[nikola].update_snap(): with file => #ok - SnapPublic', async () => {
		const fileObject = createFileObject(path.join(__dirname, 'figma_files', '5mb_components.fig'));
		const { ok: file } = await file_storage_actor_lib.nikola.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: snap } = await creator_actor_nikola.update_snap({
			id: nikola_snap_a.id,
			name: [],
			design_file: [file],
			image_cover_location: [],
			tags: [],
			images: []
		});

		if (snap) {
			expect(snap.name).toBe('First Snap Updated');
			expect(snap.tags).toEqual(['ocean']);
			expect(snap.images).toHaveLength(1);
			expect(snap.design_file).toHaveLength(1);

			// Assertions for the uploaded image and HTTP response
			const uploaded_file = snap.design_file[0];
			const img_http_response = await requestResource(uploaded_file.url);

			expect(img_http_response.statusCode).toBe(200);
			expect(uploaded_file.filename).toBe('5mb_components.fig');
			expect(uploaded_file.content_type).toBe('application/octet-stream');
			expect(uploaded_file.content_size).toBe(4473449n);
		}
	});

	test('Creator[nikola].delete_snap_design_file(): with invalid SnapID => #err - SnapNotFound', async () => {
		const { err: error } =
			await creator_actor_nikola.delete_snap_design_file('337EF5E0EF5CEAB33510XXX');

		expect(error).toEqual({ SnapNotFound: true });
	});

	test('Creator[linky].delete_snap_design_file(): with invalid caller => #err - NotOwner', async () => {
		const { err: error } = await creator_actor_linky.delete_snap_design_file(nikola_snap_a.id);

		expect(error).toEqual({ NotOwner: true });
	});

	test('Creator[nikola].delete_snap_design_file(): with valid args => #ok - Bool', async () => {
		const { ok: deleted_file } = await creator_actor_nikola.delete_snap_design_file(
			nikola_snap_a.id
		);

		expect(deleted_file).toBe(true);

		const { ok: snap } = await creator_actor_nikola.get_snap(nikola_snap_a.id);
		if (snap) {
			expect(snap.design_file).toHaveLength(0);
		}
	});

	test('Creator[nikola].delete_snaps(): with valid args => #ok - Bool', async () => {
		const { ok: deleted_snap } = await creator_actor_nikola.delete_snaps([nikola_snap_a.id]);
		expect(deleted_snap).toBe(true);

		const { err: error } = await creator_actor_nikola.get_snap(nikola_snap_a.id);
		expect(error).toEqual({ SnapNotFound: true });
	});

	test('Creator[nikola].get_project(): with valid args => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_nikola.get_project(nikola_snap_a.project_id);

		expect(project.snaps).toHaveLength(0);
	});
});
