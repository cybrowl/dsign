const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const fetch = require('node-fetch');
const { HttpAgent, Actor } = require('@dfinity/agent');

const { snap_main_interface } = require('../test-utils/actor_interface.cjs');
// Canister Ids
const {
	snap_main_canister_id,
	test_image_assets_canister_id
} = require('../test-utils/actor_canister_ids.cjs');

const get_wasm = (name) => {
	const buffer = readFileSync(`${process.cwd()}/.dfx/local/canisters/${name}/${name}.wasm`);
	return [...new Uint8Array(buffer)];
};

const get_actor = async (canisterId, can_interface) => {
	const agent = new HttpAgent({ fetch, host: 'http://127.0.0.1:8000/' });

	await agent.fetchRootKey();

	return Actor.createActor(can_interface, {
		agent,
		canisterId
	});
};

const installCode = async () => {
	let canisters = [
		{
			local: {
				name: 'snap_main',
				canister_id: snap_main_canister_id,
				can_interface: snap_main_interface,
				child_canister_principal: Principal.fromText(test_image_assets_canister_id),
				wasm: get_wasm('snap_main'),
				arg: IDL.encode([IDL.Text], [snap_main_canister_id])
			}
		}
	];

	let snap_main = canisters[0].local;

	console.log('snap_main: ', snap_main);

	const actor = await get_actor(snap_main.canister_id, snap_main.can_interface);

	console.log('actor: ', actor);

	await actor.install_code(snap_main.child_canister_principal, [...snap_main.arg], snap_main.wasm);
};

const init = async () => {
	try {
		await installCode();
	} catch (err) {
		console.error(err);
	}
};

init();
