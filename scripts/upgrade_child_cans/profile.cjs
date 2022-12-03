const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const fetch = require('node-fetch');
const { HttpAgent, Actor } = require('@dfinity/agent');
const { Secp256k1KeyIdentity } = require('@dfinity/identity');
const sha256 = require('sha256');
const fs = require('fs');
const Path = require('path');

const { profile_interface } = require('../../test-utils/actor_interface.cjs');
const { profile_canister_id } = require('../../test-utils/actor_canister_ids.cjs');
const canister_ids = require('../../canister_ids.json');

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

const get_wasm_prod = (name) => {
	const buffer = readFileSync(`${process.cwd()}/.dfx/ic/canisters/${name}/${name}.wasm`);
	return [...new Uint8Array(buffer)];
};

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
	console.log('Installing canisters...');

	let canisters = {
		local: {
			name: 'profile',
			description: 'upgrades child canister test_image_assets',
			is_prod: false,
			canister_id: profile_canister_id,
			can_interface: profile_interface,
			child_canister_text: 'si2b5-pyaaa-aaaaa-aaaja-cai',
			child_canister_principal: Principal.fromText('si2b5-pyaaa-aaaaa-aaaja-cai'),
			wasm: get_wasm('test_image_assets'),
			arg: IDL.encode([IDL.Principal, IDL.Bool], [Principal.fromText(profile_canister_id), false])
		},
		prod: {
			name: 'profile',
			description: 'upgrades child canister test_image_assets',
			is_prod: true,
			canister_id: canister_ids['profile'].ic,
			can_interface: profile_interface,
			child_canister_text: 'lewm2-iiaaa-aaaag-aat2a-cai',
			child_canister_principal: Principal.fromText('lewm2-iiaaa-aaaag-aat2a-cai'),
			wasm: get_wasm_prod('test_image_assets'),
			arg: IDL.encode(
				[IDL.Principal, IDL.Bool],
				[Principal.fromText(canister_ids['profile'].ic), true]
			)
		}
	};

	let profile = canisters.prod;

	const actor = await get_actor(profile.canister_id, profile.can_interface, profile.is_prod);

	const res = await actor.install_code(
		profile.child_canister_principal,
		[...profile.arg],
		profile.wasm
	);

	console.log('res: ', res);
};

const init = async () => {
	try {
		await installCode();
	} catch (err) {
		console.error(err);
	}
};

init();
