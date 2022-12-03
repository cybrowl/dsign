const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const fetch = require('node-fetch');
const { HttpAgent, Actor } = require('@dfinity/agent');
const { Secp256k1KeyIdentity } = require('@dfinity/identity');
const sha256 = require('sha256');
const fs = require('fs');
const Path = require('path');

const {
	canister_child_ledger_interface,
	profile_interface
} = require('../../test-utils/actor_interface.cjs');
const {
	canister_child_ledger_canister_id,
	profile_canister_id
} = require('../../test-utils/actor_canister_ids.cjs');
// const canister_ids = require('../../canister_ids.json');

const parseIdentity = (keyPath) => {
	const rawKey = fs
		.readFileSync(keyPath)
		.toString()
		.replace('-----BEGIN PRIVATE KEY-----', '')
		.replace('-----END PRIVATE KEY-----', '')
		.trim();

	const rawBuffer = Uint8Array.from(rawKey).buffer;

	const privKey = Uint8Array.from(sha256(rawBuffer, { asBytes: true }));

	// Initialize an identity from the secret key
	return Secp256k1KeyIdentity.fromSecretKey(Uint8Array.from(privKey).buffer);
};

let identity_path = Path.join(
	__dirname,
	'..',
	'..',
	'..',
	'..',
	'.config',
	'dfx',
	'identity',
	'cyberowl',
	'identity.pem'
);

const dev_identity = parseIdentity(identity_path);

const get_wasm = (name) => {
	const buffer = readFileSync(`${process.cwd()}/.dfx/local/canisters/${name}/${name}.wasm`);
	return [...new Uint8Array(buffer)];
};

// const get_wasm_prod = (name) => {
// 	const buffer = readFileSync(`${process.cwd()}/.dfx/ic/canisters/${name}/${name}.wasm`);
// 	return [...new Uint8Array(buffer)];
// };

const get_actor = async (canisterId, can_interface, is_prod) => {
	const host = is_prod ? `https://${canisterId}.ic0.app/` : `http://127.0.0.1:8080`;

	const agent = new HttpAgent({ fetch, host, identity: dev_identity });

	if (!is_prod) {
		await agent.fetchRootKey();
	}

	return Actor.createActor(can_interface, {
		agent,
		canisterId
	});
};

const installCode = async () => {
	let run_in_prod = false;

	if (run_in_prod === false) {
		console.log('======== Installing Local Profile Child Canisters =========');

		const canister_child_ledger_actor = await get_actor(
			canister_child_ledger_canister_id,
			canister_child_ledger_interface,
			false
		);

		const canister_children = await canister_child_ledger_actor.get_canisters();

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

		// prod_canisters.forEach(async (canister) => {
		// 	const actor = await get_actor(canister.canister_id, canister.can_interface, canister.is_prod);
		// 	const res = await actor.install_code(
		// 		canister.child_canister_principal,
		// 		[...canister.arg],
		// 		canister.wasm
		// 	);
		// 	console.log('res: ', res);
		// });
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
