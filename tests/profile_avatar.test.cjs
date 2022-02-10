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
const { Blob, Buffer } = require('buffer');

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
		console.log("imageAsUnit8ArrayBuffer: ", imageAsUnit8ArrayBuffer);

		const image = {
			content: [...imageAsUnit8ArrayBuffer]
		}

		const response = await profileAvatar.save(image, "mishi");

	} catch (err) {
		console.error(err);
	}

});

// test('Profile Avatar: http_request()', async function (t) {
// 	const data = JSON.stringify({
// 		todo: 'Buy the milk'
// 	});

// 	const options = {
// 		hostname: '127.0.0.1',
// 		port: 8000,
// 		secure: false,
// 		path: '/?mishi',
// 		method: 'GET',
// 		headers: {
// 			'Content-Type': 'application/json',
// 			'Content-Length': data.length
// 		}
// 	};

// 	const req = http.request(options, (res) => {
// 		console.log(`statusCode: ${res.statusCode}`);

// 		res.on('data', (d) => {
// 			console.log('data: ', data);
// 			process.stdout.write(d);
// 		});
// 	});

// 	req.on('error', (error) => {
// 		console.error(error);
// 	});

// 	req.write(data);
// 	req.end();
// });
