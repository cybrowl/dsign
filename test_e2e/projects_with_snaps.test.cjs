const test = require('tape');
const { config } = require('dotenv');
const path = require('path');
const fs = require('fs');
const { getMimeType } = require('../src/ui/utils/mime.cjs');

config();

// Actor Interface
const {
	creator_interface,
	username_registry_interface,
	file_scaling_manager_interface,
	file_storage_interface
} = require('../canister_refs/actor_interface.cjs');

// Canister Ids
const {
	username_registry_canister_id,
	file_scaling_manager_canister_id
} = require('../canister_refs/actor_canister_ids.cjs');

// Identities
const { parseIdentity } = require('./actor_identity.cjs');

let nikola_identity = parseIdentity(process.env.NIKOLA_IDENTITY);
let linky_identity = parseIdentity(process.env.LINKY_IDENTITY);
let anonymous_identity = null;

// Utils
const { getActor: get_actor } = require('./actor.cjs');
const { FileStorage } = require('../src/ui/utils/file_storage.cjs');

let username_registry_actor = {};
let file_scaling_manager_actor = {};

let project_id = '';

test('Setup Actors', async function () {
	console.log('=========== Project With Snaps ===========');

	// Username Registry
	username_registry_actor.nikola = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		nikola_identity
	);
	username_registry_actor.linky = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		linky_identity
	);
	username_registry_actor.anonymous = await get_actor(
		username_registry_canister_id,
		username_registry_interface,
		anonymous_identity
	);

	// File Scaling Manager
	file_scaling_manager_actor.nikola = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		nikola_identity
	);
	file_scaling_manager_actor.linky = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		linky_identity
	);
	file_scaling_manager_actor.anonymous = await get_actor(
		file_scaling_manager_canister_id,
		file_scaling_manager_interface,
		anonymous_identity
	);
});

test('UsernameRegistry[nikola].version(): => #ok - Nat', async function (t) {
	const version_num = await username_registry_actor.nikola.version();

	t.assert(version_num === 1n, 'Correct Version');
	t.end();
});

test('UsernameRegistry[nikola].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.nikola.create_profile('nikola');

	const { ok: deleted, err: _ } = await username_registry_actor.nikola.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[linky].delete_profile(): with valid principal => #ok - Bool', async function (t) {
	// Setup: Ensure there's a profile to delete
	await username_registry_actor.linky.create_profile('linky');

	const { ok: deleted, err: _ } = await username_registry_actor.linky.delete_profile();

	t.assert(deleted === true, 'Deleted Profile');

	t.end();
});

test('UsernameRegistry[nikola].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.nikola.create_profile('nikola');

	t.assert(username.length > 2, 'Created Profile');
	t.end();
});

test('UsernameRegistry[linky].create_profile(): with valid username => #ok - Username', async function (t) {
	const { ok: username, err: _ } = await username_registry_actor.linky.create_profile('linky');

	t.assert(username.length > 2, 'Created Profile');
});

test('Creator[nikola].create_project(): with valid args => #ok - ProjectPublic', async function (t) {
	const { ok: username_info, err: _ } =
		await username_registry_actor.nikola.get_info_by_username('nikola');

	const creator_actor_nikola = await get_actor(
		username_info.canister_id,
		creator_interface,
		nikola_identity
	);

	const { ok: project } = await creator_actor_nikola.create_project({
		name: 'Project One',
		description: ['first project']
	});

	project_id = project.id;

	t.ok(project, 'Project creation response should be ok');
	t.equal(project.name, 'Project One', 'Project name should match');
	t.deepEqual(project.description, ['first project'], 'Project description should match');
	t.end();
});

test('Creator[nikola].create_snap(): with valid project_id, name, images and img_location => #ok - SnapPublic', async function (t) {
	const fs_canister_id = await file_scaling_manager_actor.nikola.get_current_canister_id();
	const file_storage_actor = await get_actor(
		fs_canister_id,
		file_storage_interface,
		nikola_identity
	);
	const file_storage = new FileStorage(file_storage_actor);

	// Image
	const file_path = path.join(__dirname, 'images', 'size', '3mb_japan.jpg');
	const file_buffer = fs.readFileSync(file_path);
	const file_unit8Array = new Uint8Array(file_buffer);
	const file_name = path.basename(file_path);
	const file_content_type = getMimeType(file_path);

	let progressReceived = [];

	const { ok: file } = await file_storage.store(
		file_unit8Array,
		{
			filename: file_name,
			content_type: file_content_type
		},
		(progress) => {
			if (progressReceived.length === 0) {
				t.equal(progress, 0, 'Initial progress should be 0');
			} else {
				t.ok(progress > progressReceived[progressReceived.length - 1], 'Progress should increase');
			}

			progressReceived.push(progress);
		}
	);

	const { ok: username_info, err: _ } =
		await username_registry_actor.nikola.get_info_by_username('nikola');

	const creator_actor_nikola = await get_actor(
		username_info.canister_id,
		creator_interface,
		nikola_identity
	);

	const { ok: snap } = await creator_actor_nikola.create_snap({
		project_id,
		name: 'First Snap',
		tags: [],
		design_file: [],
		image_cover_location: 0,
		images: [file]
	});

	// Assertions for snap properties
	t.equal(snap.name, 'First Snap', 'Snap name should match');
	t.deepEqual(snap.tags, [], 'Snap tags should match');
	t.equal(snap.images.length, 1, 'Should have one image uploaded');

	// Assertions for the uploaded image
	const uploadedImage = snap.images[0];
	t.equal(uploadedImage.filename, '3mb_japan.jpg', 'Uploaded image filename should match');
	t.equal(uploadedImage.content_type, 'image/jpeg', 'Uploaded image content type should match');
	t.ok(uploadedImage.content_size > 0n, 'Uploaded image should have a content size');
	t.equal(
		uploadedImage.url.startsWith('http://'),
		true,
		'Uploaded image URL should start with http://'
	);
	t.equal(
		uploadedImage.canister_id,
		'a3shf-5eaaa-aaaaa-qaafa-cai',
		'Uploaded image canister ID should match'
	);

	t.end();
});
