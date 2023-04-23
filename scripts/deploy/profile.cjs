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

const installCode = async (run_in_prod, profile_canisters, wasmPath) => {
	console.log(
		run_in_prod
			? '======== Installing Prod Profile Child Canisters ========'
			: '======== Installing Local Profile Child Canisters ========'
	);

	const canisters = profile_canisters.map((canister) => {
		const profile_id = run_in_prod
			? Principal.fromText(canister_ids['profile'].ic)
			: Principal.fromText(profile_canister_id);
		const arg_map = {
			image_assets: IDL.encode([IDL.Principal, IDL.Bool], [profile_id, run_in_prod])
		};

		return {
			name: canister.name,
			is_prod: canister.isProd,
			canister_id: profile_id,
			can_interface: profile_interface,
			child_canister_principal: Principal.fromText(canister.id),
			wasm: get_wasm(`test_${canister.name}`, wasmPath),
			arg: arg_map[canister.name]
		};
	});

	canisters.forEach(async (canister) => {
		const actor = await get_actor(canister.canister_id, canister.can_interface, canister.is_prod);
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
		const run_in_prod = process.env.DEPLOY_ENV === 'prod';
		const canister_ids_ledger_actor = await get_actor(
			run_in_prod ? canister_ids['canister_ids_ledger'].ic : canister_ids_ledger_canister_id,
			canister_ids_ledger_interface,
			run_in_prod
		);
		const canister_children = await canister_ids_ledger_actor.get_canisters();
		const profile_canisters = canister_children.filter((canister) => {
			return canister.parent_name === 'Profile';
		});

		const wasmPath = run_in_prod ? '.dfx/ic/canisters' : '.dfx/local/canisters';

		await installCode(run_in_prod, profile_canisters, wasmPath);
	} catch (err) {
		console.error(err);
	}
};

init();
