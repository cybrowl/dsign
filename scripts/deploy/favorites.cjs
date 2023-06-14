const { Principal } = require('@dfinity/principal');
const { IDL } = require('@dfinity/candid');
const { readFileSync } = require('fs');
const { HttpAgent, Actor } = require('@dfinity/agent');
const { config } = require('dotenv');
const { Ed25519KeyIdentity } = require('@dfinity/identity');

config();

const {
	canister_ids_ledger_interface,
	favorite_main_interface
} = require('../../test-utils/actor_interface.cjs');
const {
	canister_ids_ledger_canister_id,
	favorite_main_canister_id
} = require('../../test-utils/actor_canister_ids.cjs');
const canister_ids = require('../../canister_ids.json');

const parseIdentity = (privateKeyHex) => {
	const privateKey = Uint8Array.from(Buffer.from(privateKeyHex, 'hex'));

	// Initialize an identity from the secret key
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

const installCode = async () => {
	console.log('Installing canisters...');

	const envConfig = {
		prod: {
			canister_ids_ledger: canister_ids['canister_ids_ledger'].ic,
			favorite_id: canister_ids['favorite_main'].ic,
			is_prod: true,
			wasm: '.dfx/ic/canisters'
		},
		staging: {
			canister_ids_ledger: canister_ids['canister_ids_ledger'].staging,
			favorite_id: canister_ids['favorite_main'].staging,
			is_prod: true,
			wasm: '.dfx/staging/canisters'
		},
		dev: {
			canister_ids_ledger: canister_ids_ledger_canister_id,
			favorite_id: favorite_main_canister_id,
			is_prod: false,
			wasm: '.dfx/local/canisters'
		},
		default: {
			canister_ids_ledger: canister_ids_ledger_canister_id,
			favorite_id: favorite_main_canister_id,
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
		config.canister_ids_ledger,
		canister_ids_ledger_interface,
		config.is_prod
	);
	const actor = await get_actor(config.favorite_id, favorite_main_interface, config.is_prod);

	const canister_children = await canister_ids_ledger_actor.get_canisters();
	const favorite_main_canisters = canister_children.filter((canister) => {
		return canister.parent_name === 'FavoriteMain';
	});

	const canisters = favorite_main_canisters.map((canister) => {
		const arg_map = {
			favorite: IDL.encode([IDL.Principal], [Principal.fromText(config.favorite_id)])
		};

		return {
			name: canister.name,
			is_prod: canister.isProd,
			canister_id: canister.id,
			principal: Principal.fromText(canister.id),
			wasm: get_wasm(`test_${canister.name}`, config.wasm),
			arg: arg_map[canister.name]
		};
	});

	canisters.forEach(async (canister) => {
		const res = await actor.install_code(canister.principal, [...canister.arg], canister.wasm);

		console.log(`Deployed ${canister.canister_id}  => `, res);
	});
};

const init = async () => {
	try {
		await installCode();
	} catch (err) {
		console.error(err);
	}
};

init();
