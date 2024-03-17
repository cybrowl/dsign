import { describe, test, expect, beforeAll } from 'vitest';
import { config } from 'dotenv';
import { canister_ids, getInterfaces } from '../config/actor_refs';

import { parseIdentity } from './actor_identity.cjs';
import { getActor } from './actor.cjs';

// Configure environment variables
config();

// Parse identities
const mishicat_identity = parseIdentity(process.env.MISHICAT_IDENTITY);
const motoko_identity = parseIdentity(process.env.MOTOKO_IDENTITY);
const anonymous_identity = null; // Assuming this means using an anonymous identity

// Setup actors object
let username_registry_actor = {};
let interfaces = {};

describe('Profile Creation Tests', () => {
	beforeAll(async () => {
		const interfaces_ = await getInterfaces();
		interfaces = interfaces_;

		// Setup Username Registry Actors
		username_registry_actor.mishicat = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			mishicat_identity
		);
		username_registry_actor.motoko = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			motoko_identity
		);
		username_registry_actor.anonymous = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			anonymous_identity
		);
	});

	test('UsernameRegistry[mishicat].version(): => #ok - Version Number', async () => {
		const version_num = await username_registry_actor.mishicat.version();
		expect(version_num).toBe(4n);
	});

	test('UsernameRegistry[mishicat].init(): => #ok - CanisterId', async () => {
		const canister_id = await username_registry_actor.mishicat.init();
		expect(canister_id.length).toBeGreaterThan(2);
	});

	test('UsernameRegistry[mishicat].delete_profile(): with valid principal => #ok - Deleted', async () => {
		// Setup: Ensure there's a profile to delete
		await username_registry_actor.mishicat.create_profile('mishicat');

		const { ok: deleted } = await username_registry_actor.mishicat.delete_profile();

		expect(deleted).toBe(true);
	});

	test('UsernameRegistry[motoko].delete_profile(): with valid principal => #ok - Deleted', async () => {
		// Setup: Ensure there's a profile to delete
		await username_registry_actor.motoko.create_profile('motoko');

		const { ok: deleted } = await username_registry_actor.motoko.delete_profile();

		expect(deleted).toBe(true);
	});

	test('UsernameRegistry[mishicat].get_username(): with invalid principal => #err - UserPrincipalNotFound', async () => {
		const { err: err_username } = await username_registry_actor.mishicat.get_username();

		expect(err_username).toEqual({ UserPrincipalNotFound: true });
	});

	test('UsernameRegistry[mishicat].get_info_by_username(): with invalid username => #err - UsernameNotFound', async () => {
		const { err: err_username } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');

		expect(err_username).toEqual({ UsernameNotFound: true });
	});

	test('UsernameRegistry[anonymous].create_profile(): with anon identity => #err - CallerAnonymous', async () => {
		const { err: err_profile } = await username_registry_actor.anonymous.create_profile('mishicat');

		expect(err_profile).toEqual({ CallerAnonymous: true });
	});

	test('UsernameRegistry[mishicat].create_profile(): with invalid username => #err - UsernameInvalid', async () => {
		const { err: err_profile } = await username_registry_actor.mishicat.create_profile('Mishicat');

		expect(err_profile).toEqual({ UsernameInvalid: true });
	});

	test('UsernameRegistry[mishicat].create_profile(): with valid username => #ok - Created Profile', async () => {
		const { ok: username } = await username_registry_actor.mishicat.create_profile('mishicat');

		expect(username.length).toBeGreaterThan(2);
	});

	test('UsernameRegistry[motoko].create_profile(): with valid username => #ok - Created Profile', async () => {
		const { ok: username } = await username_registry_actor.motoko.create_profile('motoko');

		expect(username.length).toBeGreaterThan(2);
	});

	test('UsernameRegistry[mishicat].create_profile(): with taken username => #ok - UsernameTaken', async () => {
		const { err: err_profile } = await username_registry_actor.mishicat.create_profile('mishicat');

		expect(err_profile).toEqual({ UsernameTaken: true });
	});

	test('Creator[mishicat].total_profiles(): => #ok - NumberOfUsers', async () => {
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const creator_actor_mishicat = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const users_total = await creator_actor_mishicat.total_profiles();

		expect(users_total).toBeGreaterThan(0);
	});

	test('Creator[mishicat].get_profile_by_username(): with valid username & owner => #ok - Profile', async () => {
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const validUsername = 'mishicat';
		const creator_actor = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const { ok: profile, err: errProfile } =
			await creator_actor.get_profile_by_username(validUsername);

		expect(profile).toBeTruthy();
		expect(profile.username).toEqual(validUsername);
		expect(profile.is_owner).toBe(true);
		expect(profile.favorites).toEqual([]);
		expect(profile.projects).toEqual([]);
		expect(profile.storage_metrics).toEqual([]);
		expect(profile.banner).toEqual({ id: '', url: '/default_profile_banner.png', canister_id: '' });
		expect(profile.avatar).toEqual({ id: '', url: '', canister_id: '' });
		expect(errProfile).toBeFalsy();
	});

	test('Creator[mishicat].get_profile_by_username(): with valid username & NOT owner => #ok - Profile', async () => {
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const validUsername = 'motoko';
		const creator_actor = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const { ok: profile, err: errProfile } =
			await creator_actor.get_profile_by_username(validUsername);

		expect(profile).toBeTruthy();
		expect(profile.username).toEqual(validUsername);
		expect(profile.is_owner).toBe(false);
		expect(errProfile).toBeFalsy();
	});

	test('Creator[mishicat].get_profile_by_username(): with invalid username => #err - ProfileNotFound', async () => {
		const invalidUsername = 'nonexistentuser';
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const creator_actor = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const { err: errProfile } = await creator_actor.get_profile_by_username(invalidUsername);

		expect(errProfile).toEqual({ ProfileNotFound: true });
	});

	test('Creator[mishicat].get_canister_id(): => #ok - Canister ID', async () => {
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const creator_actor_mishicat = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const canisterId = await creator_actor_mishicat.get_canister_id();

		expect(typeof canisterId === 'string' && canisterId.length > 0).toBe(true);
	});

	test('Creator[mishicat].get_canister_id(): => #ok - Format Check', async () => {
		const { ok: username_info } =
			await username_registry_actor.mishicat.get_info_by_username('mishicat');
		const creator_actor_mishicat = await getActor(
			username_info.canister_id,
			interfaces.creator,
			mishicat_identity
		);
		const canisterId = await creator_actor_mishicat.get_canister_id();
		const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
		const isValidFormat = pattern.test(canisterId);

		expect(isValidFormat).toBe(true);
	});
});
