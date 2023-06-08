const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const { HttpAgent, Actor } = require('@dfinity/agent');
const { config } = require('dotenv');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

//NOTE: if fetch isn't working use node version 18
config();

const {
	canister_ids_ledger_interface,
	profile_interface
} = require('../../test-utils/actor_interface.cjs');
const {
	canister_ids_ledger_canister_id,
	profile_canister_id
} = require('../../test-utils/actor_canister_ids.cjs');

const canister_ids = require('../../canister_ids.json');

const parseIdentity = (privateKeyHex) => {
	const privateKey = Uint8Array.from(Buffer.from(privateKeyHex, 'hex'));
	return Ed25519KeyIdentity.fromSecretKey(privateKey);
};

const dev_identity = parseIdentity(process.env.ADMIN_IDENTITY);

const get_wasm = (name, wasmPath) => {
	const buffer = readFileSync(`${process.cwd()}/${wasmPath}/${name}/${name}.wasm`);
	return [...new Uint8Array(buffer)];
};

const get_actor = async (canisterId, can_interface, is_prod) => {
	const host = is_prod ? `https://${canisterId}.icp0.io/` : `http://127.0.0.1:8080`;
	const agent = new HttpAgent({ host, identity: dev_identity });

	if (!is_prod) {
		await agent.fetchRootKey();
	}

	return Actor.createActor(can_interface, {
		agent,
		canisterId
	});
};

const installCode = async (profile_child_canisters, profile_id, is_prod, wasm) => {
	console.log('profile_child_canisters: ', profile_child_canisters);
	console.log('is_prod: ', is_prod);
	console.log('wasm: ', wasm);

	const profile_id_principal = Principal.fromText(profile_id);

	const canisters = profile_child_canisters.map((canister) => {
		const arg_map = {
			image_assets: IDL.encode([IDL.Principal, IDL.Bool], [profile_id_principal, is_prod])
		};

		return {
			name: canister.name,
			is_prod: canister.isProd,
			canister_id_principal: profile_id_principal,
			canister_id: profile_id,
			can_interface: profile_interface,
			child_canister_principal: Principal.fromText(canister.id),
			child_canister_id: canister.id,
			wasm: get_wasm(`test_${canister.name}`, wasm),
			arg: arg_map[canister.name]
		};
	});

	console.log('canisters: ', canisters);

	canisters.forEach(async (canister) => {
		const actor = await get_actor(
			canister.canister_id_principal,
			canister.can_interface,
			canister.is_prod
		);
		const res = await actor.install_code(
			canister.child_canister_principal,
			[...canister.arg],
			canister.wasm
		);

		console.log('done => ', res);
	});
};

const init = async () => {
	try {
		const envConfig = {
			prod: {
				canister_id: canister_ids['canister_ids_ledger'].ic,
				profile_id: canister_ids['profile'].ic,
				is_prod: true,
				wasm: '.dfx/ic/canisters'
			},
			// staging: {
			// 	canister_id: canister_ids['canister_ids_ledger'].staging,
			// 	profile_id: canister_ids['profile'].staging,
			// 	is_prod: true,
			// 	wasm: '.dfx/staging/canisters'
			// },
			dev: {
				canister_id: canister_ids_ledger_canister_id,
				profile_id: profile_canister_id,
				is_prod: false,
				wasm: '.dfx/local/canisters'
			},
			default: {
				canister_id: canister_ids_ledger_canister_id,
				profile_id: profile_canister_id,
				is_prod: false,
				wasm: '.dfx/local/canisters'
			}
		};

		const env = process.env.DEPLOY_ENV;

		console.log('--------------------------');
		console.log('env: ', env);
		console.log('--------------------------');

		const config = envConfig[env] || envConfig['default'];

		const canister_ids_ledger_actor = await get_actor(
			config.canister_id,
			canister_ids_ledger_interface,
			config.is_prod
		);

		const canister_children = await canister_ids_ledger_actor.get_canisters();

		const profile_child_canisters = canister_children.filter((canister) => {
			return canister.parent_name === 'Profile';
		});

		await installCode(profile_child_canisters, config.profile_id, config.is_prod, config.wasm);
	} catch (err) {
		console.error(err);
	}
};

init();
