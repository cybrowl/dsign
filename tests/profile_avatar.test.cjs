// const test = require('tape');
// const fetch = require('node-fetch');
// const { getActor } = require('./actor.cjs');
// const canisterIds = require('../.dfx/local/canister_ids.json');
// const {
// 	idlFactory
// } = require('../.dfx/local/canisters/profile_avatar/profile_avatar.did.test.cjs');
// const { Ed25519KeyIdentity } = require('@dfinity/identity');
// const http = require('http');
// const fs = require('fs');

// global.fetch = fetch;

// let Mishi = Ed25519KeyIdentity.generate();
// const canisterId = canisterIds.profile_avatar.local;
// let profileAvatar = null;
// let avatarCanister = "rno2w-sqaaa-aaaaa-aaacq-cai";

// function callImageCanister(path) {
// 	const options = {
// 		hostname: '127.0.0.1',
// 		port: 8000,
// 		secure: false,
// 		path: path,
// 		method: 'GET',
// 		headers: {
// 			'Content-Type': 'image/png'
// 		}
// 	};

// 	return new Promise(function (resolve, reject) {
// 		const req = http.request(options, (res) => {
// 			resolve(res);
// 		});

// 		req.on('error', (error) => {
// 			reject(error);
// 		});
// 		req.end();
// 	});
// }

// test('Profile Avatar: ping()', async function (t) {
// 	profileAvatar = await getActor(canisterId, idlFactory, Mishi);

// 	const response = await profileAvatar.ping();

// 	t.equal(typeof response, 'string');
// 	t.equal(response, 'meow');
// });

// test('Profile Avatar: set()', async function (t) {
// 	try {
// 		const imageAsBuffer = fs.readFileSync('tests/images/motoko.png');

// 		// covert to unit 8 array
// 		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
// 		const image = {
// 			content: [...imageAsUnit8ArrayBuffer]
// 		};

// 		const response = await profileAvatar.set(image, 'mishi');
// 	} catch (err) {
// 		console.error(err);
// 	}
// });

// test('Profile Avatar: should find avatar', async function (t) {
// 	const path = `https://kqlfj-siaaa-aaaag-aaawq-cai.raw.ic0.app/avatar/mishi?canisterId=${avatarCanister}`;
// 	let response = await callImageCanister(path);

// 	t.strictEqual(response.statusCode, 200);
// });

// test('Profile Avatar: should NOT find avatar', async function (t) {
// 	const path = `https://kqlfj-siaaa-aaaag-aaawq-cai.raw.ic0.app/avatar/mish?canisterId=${avatarCanister}`;
// 	let response = await callImageCanister(path);

// 	t.strictEqual(response.statusCode, 404);
// });


// test('Profile Avatar: save over 2MB()', async function (t) {
// 	try {
// 		const imageAsBuffer = fs.readFileSync('tests/images/image_2MB.png');

// 		// covert to unit 8 array
// 		const imageAsUnit8ArrayBuffer = new Uint8Array(imageAsBuffer);
// 		const image = {
// 			content: [...imageAsUnit8ArrayBuffer]
// 		};

// 		const response = await profileAvatar.set(image, 'mishito');
// 	} catch (err) {
// 		console.error(err);
// 	}
// });

// test('Profile Avatar: should NOT find avatar', async function (t) {
// 	const path = `https://kqlfj-siaaa-aaaag-aaawq-cai.raw.ic0.app/avatar/mishito?canisterId=${avatarCanister}`;
// 	let response = await callImageCanister(path);

// 	t.strictEqual(response.statusCode, 404);
// });