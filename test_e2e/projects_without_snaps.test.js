import { describe, test, expect, beforeAll } from 'vitest';
import { config } from 'dotenv';
import { parseIdentity } from './actor_identity.cjs';
import { getActor } from './actor.cjs';
import { canister_ids, getInterfaces } from '../config/actor_refs';

config();

// Setup actors here, assuming async initialization
const owl_identity = parseIdentity(process.env.OWL_IDENTITY);
const dominic_identity = parseIdentity(process.env.DOMINIC_IDENTITY);
const anonymous_identity = null; // Assuming this represents using an anonymous identity

let project_id = '';
let interfaces = {};
let username_registry_actor = {};

let creator_actor_owl = {};

// Assuming you have these utilities correctly set up in your project context
describe('Projects Without Snaps Tests', async () => {
	beforeAll(async () => {
		interfaces = await getInterfaces();

		username_registry_actor.owl = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			owl_identity
		);
		username_registry_actor.dominic = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			dominic_identity
		);
		username_registry_actor.anonymous = await getActor(
			canister_ids.username_registry,
			interfaces.username_registry,
			anonymous_identity
		);
	});

	test('UsernameRegistry[owl].version(): => #ok - Nat', async () => {
		const version_num = await username_registry_actor.owl.version();
		expect(version_num).toBe(1n);
	});

	test('UsernameRegistry[owl].delete_profile(): with valid principal => #ok - Bool', async () => {
		await username_registry_actor.owl.create_profile('owl');
		const { ok: deleted } = await username_registry_actor.owl.delete_profile();
		expect(deleted).toBe(true);
	});

	test('UsernameRegistry[dominic].delete_profile(): with valid principal => #ok - Bool', async () => {
		await username_registry_actor.dominic.create_profile('dominic');
		const { ok: deleted } = await username_registry_actor.dominic.delete_profile();
		expect(deleted).toBe(true);
	});

	test('UsernameRegistry[owl].create_profile(): with valid username => #ok - Username', async () => {
		const { ok: username } = await username_registry_actor.owl.create_profile('owl');
		expect(username.length).toBeGreaterThan(2);
	});

	test('UsernameRegistry[dominic].create_profile(): with valid username => #ok - Username', async () => {
		const { ok: username } = await username_registry_actor.dominic.create_profile('dominic');
		expect(username.length).toBeGreaterThan(2);
	});

	test('Creator[owl].total_users(): => #ok - NumberOfUsers', async () => {
		const { ok: username_info } = await username_registry_actor.owl.get_info_by_username('owl');

		creator_actor_owl = await getActor(username_info.canister_id, interfaces.creator, owl_identity);

		const users_total = await creator_actor_owl.total_users();

		expect(users_total).toBeGreaterThan(0);
	});

	test('Creator[owl].create_project(): with valid args => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_owl.create_project({
			name: 'Project One',
			description: ['first project']
		});

		project_id = project.id;

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[owl].get_project(): with valid id => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_owl.get_project(project_id);

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[owl].get_profile_by_username(): with valid username => #ok - ProfilePublic', async () => {
		const { ok: profile } = await creator_actor_owl.get_profile_by_username('owl');

		expect(profile).toBeTruthy();
		expect(profile.projects).toHaveLength(1);
		expect(profile.projects[0].name).toBe('Project One');
		expect(typeof profile.projects[0].canister_id).toBe('string');

		// Check if the canister ID matches the expected format
		const pattern = /^[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[a-z2-7]{5}-[cai]{3}$/;
		expect(pattern.test(profile.projects[0].canister_id)).toBe(true);

		expect(profile.is_owner).toBe(true);
	});

	test('Creator[owl].update_project(): with no optional args => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_owl.update_project({
			id: project_id,
			name: [],
			description: []
		});

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[owl].update_project(): with name only => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_owl.update_project({
			id: project_id,
			name: ['Project One Updated'],
			description: []
		});

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One Updated');
		expect(project.description).toEqual(['first project']);
	});

	test('Creator[owl].update_project(): with description only => #ok - ProjectPublic', async () => {
		const { ok: project } = await creator_actor_owl.update_project({
			id: project_id,
			name: [],
			description: ['first project updated']
		});

		expect(project).toBeTruthy();
		expect(project.name).toBe('Project One Updated');
		expect(project.description).toEqual(['first project updated']);
	});

	test('Creator[owl].delete_project(): with valid id => #ok - Bool', async () => {
		const { ok: deleted } = await creator_actor_owl.delete_project(project_id);
		expect(deleted).toBe(true);
	});

	test('Creator[owl].get_project(): with invalid id => #err - ProjectNotFound', async () => {
		const { err: error } = await creator_actor_owl.get_project('invalid_project_id');
		expect(error).toEqual({ ProjectNotFound: true });
	});

	test('Creator[owl].get_profile_by_username(): with valid username => #ok - ProfilePublic', async () => {
		const { ok: profile } = await creator_actor_owl.get_profile_by_username('owl');
		expect(profile).toBeTruthy();
		expect(profile.projects.length).toBe(0);
	});
});
