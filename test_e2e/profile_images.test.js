import { describe, test, expect, beforeAll } from 'vitest';
import { config } from 'dotenv';
import path from 'path';

import { canister_ids, getInterfaces } from '../config/actor_refs';
import { parseIdentity } from './actor_identity.cjs';
import { getActor } from './actor.cjs';

import { FileStorage } from '../src/ui/utils/file_storage';
import { createFileObject } from './libs/file';

// Configure environment variables
config();

// Identities
const nova_identity = parseIdentity(process.env.NOVA_IDENTITY);
const daphne_identity = parseIdentity(process.env.DAPHNE_IDENTITY);
const anonymous_identity = null; // Assuming this means using an anonymous identity

let interfaces = {};

let username_registry_actor = {};
let file_scaling_manager_actor = {};
let file_storage_actor_lib = {};

describe('Profile Images Tests', () => {
	beforeAll(async () => {
		interfaces = await getInterfaces();

		// Setup Username Registry Actors
		username_registry_actor.nova = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			nova_identity
		);
		username_registry_actor.daphne = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			daphne_identity
		);
		username_registry_actor.anonymous = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			anonymous_identity
		);

		// Setup File Scaling Manager Actors
		file_scaling_manager_actor.nova = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			nova_identity
		);
		file_scaling_manager_actor.daphne = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			daphne_identity
		);
		file_scaling_manager_actor.anonymous = await getActor(
			canister_ids.file_scaling_manager,
			interfaces.file_scaling_manager,
			anonymous_identity
		);

		const fs_canister_id = await file_scaling_manager_actor.nova.get_current_canister_id();
		const file_storage_actor = await getActor(
			fs_canister_id,
			interfaces.file_storage,
			nova_identity
		);

		file_storage_actor_lib.nova = new FileStorage(file_storage_actor);
	});

	test('FileScalingManager[nova].init(): => #ok - CanisterId', async () => {
		const canister_id = await file_scaling_manager_actor.nova.init();
		expect(canister_id.length).toBeGreaterThan(2);
	});

	test('FileScalingManager[nova].get_current_canister_id(): => #ok - CanisterId', async () => {
		const canister_id = await file_scaling_manager_actor.nova.get_current_canister_id();

		// Example regex for basic validation, adjust according to your expected format
		const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
		const isValidFormat = pattern.test(canister_id);

		expect(isValidFormat).toBe(true);
	});

	test('FileScalingManager[nova].get_current_canister(): => #ok - canister', async () => {
		const canister = await file_scaling_manager_actor.nova.get_current_canister();

		expect(canister).toBeInstanceOf(Array);
		expect(canister).toHaveLength(1);

		const actualCanister = canister[0];

		expect(typeof actualCanister.id).toBe('string');
		expect(actualCanister.status).toBeInstanceOf(Array);
		expect(typeof actualCanister.created).toBe('bigint');
		expect(actualCanister.name).toBe('file_storage');
		expect(actualCanister.parent_name).toBe('FileScalingManager');
	});

	test('FileScalingManager[nova].get_file_storage_registry_size(): => #ok - size', async () => {
		const size = await file_scaling_manager_actor.nova.get_file_storage_registry_size();
		expect(size).toBe(1n);
	});

	test('UsernameRegistry[nova].delete_profile(): with valid principal => #ok - Deleted', async () => {
		// Setup: Ensure there's a profile to delete
		await username_registry_actor.nova.create_profile('nova');
		const { ok: deleted } = await username_registry_actor.nova.delete_profile();
		expect(deleted).toBe(true);
	});

	test('UsernameRegistry[nova].create_profile(): with valid username => #ok - Created Profile', async () => {
		const { ok: username } = await username_registry_actor.nova.create_profile('nova');
		expect(username.length).toBeGreaterThan(2);
	});

	test('FileStorage[nova].create_chunk & create_file_from_chunks(): => #ok - File Stored', async () => {
		const filePath = path.join(__dirname, 'images', 'size', '3mb_japan.jpg');
		const fileObject = createFileObject(filePath);

		const { ok: file } = await file_storage_actor_lib.nova.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		expect(file).toBeTruthy();
		expect(typeof file.id).toBe('string');
		expect(file.url).toContain(file.id);
		expect(file.chunks_size).toBe(2n);
		expect(file.content_size).toBe(3628429n);
		expect(file.content_type).toBe('image/jpeg');
		expect(file.name).toBe('3mb_japan.jpg');
		expect(file.content_encoding).toEqual({ Identity: null });
	}, 10000);

	test('Creator[nova].update_profile_avatars(): => #ok - Updated Avatar', async () => {
		const filePath = path.join(__dirname, 'images', 'size', '3mb_japan.jpg');
		const fileObject = createFileObject(filePath);
		const { ok: file } = await file_storage_actor_lib.nova.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: username_info } = await username_registry_actor.nova.get_info_by_username('nova');

		const creator_actor = await getActor(
			username_info.canister_id,
			interfaces.creator,
			nova_identity
		);

		const updated_profile = await creator_actor.update_profile_avatar({
			id: file.id,
			canister_id: file.canister_id,
			url: file.url
		});

		const { ok: profile } = await creator_actor.get_profile_by_username('nova');

		expect(profile.avatar.id).toBe(file.id);
		expect(profile.avatar.canister_id).toBe(file.canister_id);
		expect(profile.avatar.url).toBe(file.url);
		expect(profile.avatar.url.startsWith('http://')).toBe(true);
		expect(() => new URL(profile.avatar.url)).not.toThrow();
		expect(updated_profile.ok).toBeTruthy();
		expect(updated_profile.err).toBeFalsy();
	});

	test('Creator[nova].update_profile_banner(): => #ok - Updated Banner', async () => {
		const filePath = path.join(__dirname, 'images', 'size', '3mb_japan.jpg');
		const fileObject = createFileObject(filePath);
		const { ok: file } = await file_storage_actor_lib.nova.store(fileObject.content, {
			filename: fileObject.name,
			content_type: fileObject.type
		});

		const { ok: username_info } = await username_registry_actor.nova.get_info_by_username('nova');

		const creator_actor = await getActor(
			username_info.canister_id,
			interfaces.creator,
			nova_identity
		);

		const updated_profile = await creator_actor.update_profile_banner({
			id: file.id,
			canister_id: file.canister_id,
			url: file.url
		});

		const { ok: profile } = await creator_actor.get_profile_by_username('nova');

		expect(profile.banner.id).toBe(file.id);
		expect(profile.banner.canister_id).toBe(file.canister_id);
		expect(profile.banner.url).toBe(file.url);
		expect(profile.banner.url.startsWith('http://')).toBe(true);
		expect(() => new URL(profile.banner.url)).not.toThrow();
		expect(updated_profile.ok).toBeTruthy();
		expect(updated_profile.err).toBeFalsy();
	});
});
