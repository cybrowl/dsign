// const { Principal } = require('@dfinity/principal');
// const { IDL } = require('@dfinity/candid');
// const { readFileSync } = require('fs');
// const fetch = require('node-fetch');
// const { HttpAgent, Actor } = require('@dfinity/agent');
// const { Secp256k1KeyIdentity } = require('@dfinity/identity');
// const sha256 = require('sha256');
// const fs = require('fs');
// const Path = require('path');

// const { project_main_interface } = require('../../test-utils/actor_interface.cjs');
// const { project_main_canister_id } = require('../../test-utils/actor_canister_ids.cjs');
// const canister_ids = require('../../canister_ids.json');

// const parseIdentity = (keyPath) => {
// 	const rawKey = fs
// 		.readFileSync(keyPath)
// 		.toString()
// 		.replace('-----BEGIN PRIVATE KEY-----', '')
// 		.replace('-----END PRIVATE KEY-----', '')
// 		.trim();

// 	const rawBuffer = Uint8Array.from(rawKey).buffer;

// 	const privKey = Uint8Array.from(sha256(rawBuffer, { asBytes: true }));

// 	// Initialize an identity from the secret key
// 	return Secp256k1KeyIdentity.fromSecretKey(Uint8Array.from(privKey).buffer);
// };

// let identity_path = Path.join(
// 	__dirname,
// 	'..',
// 	'..',
// 	'..',
// 	'..',
// 	'.config',
// 	'dfx',
// 	'identity',
// 	'cyberowl',
// 	'identity.pem'
// );

// const dev_identity = parseIdentity(identity_path);

// console.log('dev_identity', dev_identity.getPrincipal().toText());
// console.log('project_main');

// const get_wasm = (name) => {
// 	const buffer = readFileSync(`${process.cwd()}/.dfx/local/canisters/${name}/${name}.wasm`);
// 	return [...new Uint8Array(buffer)];
// };

// const get_wasm_prod = (name) => {
// 	const buffer = readFileSync(`${process.cwd()}/.dfx/ic/canisters/${name}/${name}.wasm`);
// 	return [...new Uint8Array(buffer)];
// };

// const get_actor = async (canisterId, can_interface, is_prod) => {
// 	const host = is_prod ? `https://${canisterId}.ic0.app/` : `http://127.0.0.1:8000`;

// 	const agent = new HttpAgent({ fetch, host, identity: dev_identity });

// 	if (!is_prod) {
// 		await agent.fetchRootKey();
// 	}

// 	return Actor.createActor(can_interface, {
// 		agent,
// 		canisterId
// 	});
// };

// const installCode = async () => {
// 	console.log('Installing canisters...');

// 	let canisters = [
// 		{
// 			local: {
// 				name: 'project_main',
// 				description: 'upgrades child canister project',
// 				is_prod: false,
// 				canister_id: project_main_canister_id,
// 				can_interface: project_main_interface,
// 				child_canister_text: 'sgymv-uiaaa-aaaaa-aaaia-cai',
// 				child_canister_principal: Principal.fromText('sgymv-uiaaa-aaaaa-aaaia-cai'),
// 				wasm: get_wasm('test_project'),
// 				arg: IDL.encode(
// 					[IDL.Principal, IDL.Bool],
// 					[Principal.fromText(project_main_canister_id), false]
// 				)
// 			}
// 			// prod: {
// 			// 	name: 'project_main',
// 			// 	description: 'upgrades child canister test_image_assets',
// 			// 	is_prod: true,
// 			// 	canister_id: canister_ids['snap_main'].ic,
// 			// 	can_interface: project_main_interface,
// 			// 	child_canister_text: 'lwq3d-eyaaa-aaaag-aatza-cai',
// 			// 	child_canister_principal: Principal.fromText('lwq3d-eyaaa-aaaag-aatza-cai'),
// 			// 	wasm: get_wasm_prod('test_image_assets'),
// 			// 	arg: IDL.encode(
// 			// 		[IDL.Principal, IDL.Bool],
// 			// 		[Principal.fromText(canister_ids['snap_main'].ic), true]
// 			// 	)
// 			// }
// 		}
// 	];

// 	let project_main = canisters[0].local;

// 	const actor = await get_actor(
// 		project_main.canister_id,
// 		project_main.can_interface,
// 		project_main.is_prod
// 	);

// 	const res = await actor.install_code(
// 		project_main.child_canister_principal,
// 		[...project_main.arg],
// 		project_main.wasm
// 	);

// 	console.log('res: ', res);
// };

// const init = async () => {
// 	try {
// 		await installCode();
// 	} catch (err) {
// 		console.error(err);
// 	}
// };

// init();
