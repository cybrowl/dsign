import { config as load_env_config } from 'dotenv';
import { Ed25519KeyIdentity } from '@dfinity/identity';
import { HttpAgent, Actor } from '@dfinity/agent';
import { IDL } from '@dfinity/candid';
import { Principal } from '@dfinity/principal';
import { readFileSync } from 'fs';
const canister_ids_config = await import('../canister_ids.json', {
	assert: { type: 'json' }
});

import { canister_ids, getInterfaces } from '../config/actor_refs.js';

load_env_config();

const parse_identity = (private_key_hex) =>
	Ed25519KeyIdentity.fromSecretKey(Uint8Array.from(Buffer.from(private_key_hex, 'hex')));

const dev_identity = parse_identity(process.env.ADMIN_IDENTITY);

const get_wasm_module = (name, path) =>
	readFileSync(`${process.cwd()}/${path}/${name}/${name}.wasm`);

const create_actor = async (canister_id, actor_interface, is_prod) => {
	// Validation adjustments
	if (typeof canister_id !== 'string' || canister_id.trim() === '') {
		throw new Error('Invalid canister_id: Must be a non-empty string.');
	}

	// Updated to check if actor_interface is directly a function
	if (typeof actor_interface !== 'function') {
		throw new Error('create_actor: Invalid actor_interface. Expected a function.');
	}

	if (typeof is_prod !== 'boolean') {
		throw new Error('Invalid is_prod: Must be a boolean.');
	}

	const host = is_prod ? `https://${canister_id}.icp0.io/` : 'http://127.0.0.1:8080';
	const agent = new HttpAgent({ host, identity: dev_identity });

	if (!is_prod) await agent.fetchRootKey();

	try {
		// Note the interface is passed directly as it's expected to be a function
		return Actor.createActor(actor_interface, { agent, canisterId: canister_id });
	} catch (error) {
		console.error(`Error creating actor for canister_id ${canister_id}:`, error);
		throw new Error(`Failed to create actor: ${error.message}`);
	}
};

const init = async () => {
	try {
		const actor_interfaces = (await getInterfaces()) || {};
		const env = process.env.DEPLOY_ENV || 'local';

		const env_config = {
			prod: {
				file_scaling_manager_cid: canister_ids_config.default['file_scaling_manager'].ic,
				username_registry_cid: canister_ids_config.default['username_registry'].ic,
				wasm_path: `.dfx/${env}/canisters`,
				is_prod: true
			},
			staging: {
				file_scaling_manager_cid: canister_ids_config.default['file_scaling_manager'].staging,
				username_registry_cid: canister_ids_config.default['username_registry'].staging,
				wasm_path: `.dfx/${env}/canisters`,
				is_prod: true
			},
			local: {
				file_scaling_manager_cid: canister_ids['file_scaling_manager'],
				username_registry_cid: canister_ids['username_registry'],
				wasm_path: `.dfx/${env}/canisters`,
				is_prod: false
			}
		};

		console.log('--------------------------');
		console.log(`Environment: ${env}`);
		console.log('--------------------------');
		console.log('======== Installing Child Canisters ========');

		const config = env_config[env];

		const file_scaling_manager_actor = await create_actor(
			config.file_scaling_manager_cid,
			actor_interfaces.file_scaling_manager,
			config.is_prod
		);

		const username_registry_actor = await create_actor(
			config.username_registry_cid,
			actor_interfaces.username_registry,
			config.is_prod
		);

		const fs_registry = await file_scaling_manager_actor.get_file_storage_registry();

		console.log('======== Installing Children File Storage Manager ========');
		for (const canister of fs_registry) {
			const wasm_module = get_wasm_module(canister.name, config.wasm_path);

			const encoded_args = IDL.encode([IDL.Bool, IDL.Text], [config.is_prod, '8080']);
			console.log('canister: ', canister);

			// const response = await file_scaling_manager_actor.install_code(
			// 	Principal.fromText(canister.id),
			// 	[...encoded_args],
			// 	wasm_module
			// );

			// console.log(`Deployed ${canister.canister_id} =>`, response);
		}

		const actor_registry = await username_registry_actor.get_registry();

		console.log('======== Installing Children Username Registry ========');
		for (const canister of actor_registry) {
			const wasm_module = get_wasm_module(canister.name, config.wasm_path);

			const encoded_args = IDL.encode(
				[IDL.Principal],
				[Principal.fromText(config.username_registry_cid)]
			);
			console.log('canister: ', canister);

			// const response = await username_registry_actor.install_code(
			// 	Principal.fromText(canister.id),
			// 	[...encoded_args],
			// 	wasm_module
			// );

			// console.log(`Deployed ${canister.canister_id} =>`, response);
		}
	} catch (err) {
		console.error(err);
	}
};

init();
