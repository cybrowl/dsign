const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const { HttpAgent, Actor } = require('@dfinity/agent');
const { config } = require('dotenv');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

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

	// Initialize an identity from the secret key
	return Ed25519KeyIdentity.fromSecretKey(privateKey);
};

const dev_identity = parseIdentity(process.env.ADMIN_IDENTITY);

const get_wasm = (name) => {
	const buffer = readFileSync(`${process.cwd()}/.dfx/local/canisters/${name}/${name}.wasm`);
	return [...new Uint8Array(buffer)];
};

const get_wasm_prod = (name) => {
	const buffer = readFileSync(`${process.cwd()}/.dfx/ic/canisters/${name}/${name}.wasm`);
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

const installCode = async () => {
	let run_in_prod = process.env.DEPLOY_ENV === 'prod' ? true : false;

	if (run_in_prod === false) {
		console.log('======== Installing Local Profile Child Canisters =========');

		const canister_ids_ledger_actor = await get_actor(
			canister_ids_ledger_canister_id,
			canister_ids_ledger_interface,
			false
		);

		const canister_children = await canister_ids_ledger_actor.get_canisters();

		const profile_canisters = canister_children.filter((canister) => {
			return canister.parent_name == 'Profile';
		});

		const local_canisters = profile_canisters.map((canister) => {
			const arg_map = {
				image_assets: IDL.encode(
					[IDL.Principal, IDL.Bool],
					[Principal.fromText(profile_canister_id), false]
				)
			};

			return {
				name: canister.name,
				is_prod: canister.isProd,
				canister_id: profile_canister_id,
				can_interface: profile_interface,
				child_canister_principal: Principal.fromText(canister.id),
				wasm: get_wasm(`test_${canister.name}`),
				arg: arg_map[canister.name]
			};
		});

		local_canisters.forEach(async (canister) => {
			const actor = await get_actor(canister.canister_id, canister.can_interface, canister.is_prod);

			const res = await actor.install_code(
				canister.child_canister_principal,
				[...canister.arg],
				canister.wasm
			);

			console.log('done => ', res);
		});
	} else {
		console.log('======== Installing Prod Profile Child Canisters =========');

		const canister_ids_ledger_actor = await get_actor(
			canister_ids['canister_ids_ledger'].ic,
			canister_ids_ledger_interface,
			true
		);

		const canister_children = await canister_ids_ledger_actor.get_canisters();

		const profile_canisters = canister_children.filter((canister) => {
			return canister.parent_name == 'Profile';
		});

		const prod_canisters = profile_canisters.map((canister) => {
			const arg_map = {
				image_assets: IDL.encode(
					[IDL.Principal, IDL.Bool],
					[Principal.fromText(canister_ids['profile'].ic), true]
				)
			};

			return {
				name: canister.name,
				is_prod: canister.isProd,
				canister_id: canister_ids['profile'].ic,
				can_interface: profile_interface,
				child_canister_principal: Principal.fromText(canister.id),
				wasm: get_wasm_prod(`test_${canister.name}`),
				arg: arg_map[canister.name]
			};
		});

		prod_canisters.forEach(async (canister) => {
			const actor = await get_actor(canister.canister_id, canister.can_interface, canister.is_prod);

			const res = await actor.install_code(
				canister.child_canister_principal,
				[...canister.arg],
				canister.wasm
			);

			console.log('done => ', res);
		});
	}
};

const init = async () => {
	try {
		await installCode();
	} catch (err) {
		console.error(err);
	}
};

init();
