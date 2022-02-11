const test = require('tape');
const fetch = require('node-fetch');
const { getActor } = require('./actor.cjs');
const canisterIds = require('../.dfx/local/canister_ids.json');
const {
	idlFactory
} = require('../.dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs');
const { Ed25519KeyIdentity } = require('@dfinity/identity');
const http = require('http');
const fs = require('fs');

global.fetch = fetch;

let Mishi = Ed25519KeyIdentity.generate();
const canisterId = canisterIds.profile_avatar.local;
let profileAvatar = null;

test('Profile Avatar: ping()', async function (t) {
	profileAvatar = await getActor(canisterId, idlFactory, Mishi);

	const response = await profileAvatar.ping();

	t.equal(typeof response, 'string');
	t.equal(response, 'meow');
});

test('Profile Avatar: save()', async function (t) {
	try {
		const imageAsBuffer = fs.readFileSync('tests/images/motoko.png');

		// covert to unit 8 array
		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
		const image = {
			content: [...imageAsUnit8ArrayBuffer]
		};

		const response = await profileAvatar.save(image, 'mishi');
	} catch (err) {
		console.error(err);
	}
});

function callImageCanister() {
	const options = {
		hostname: '127.0.0.1',
		port: 8000,
		secure: false,
		path: '/avatar/mishi?canisterId=qaa6y-5yaaa-aaaaa-aaafa-cai',
		method: 'GET',
		headers: {
			'Content-Type': 'image/png'
		}
	};

	return new Promise(function (resolve, reject) {
		const req = http.request(options, (res) => {
			resolve(res);
		});

		req.on('error', (error) => {
			reject(error);
		});
		req.end();
	});
}

test('Profile Avatar: http_request()', async function (t) {
	let response = await callImageCanister();

	t.strictEqual(response.statusCode, 200);
});
