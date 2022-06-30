const test = require('tape');
const { generateCanisterAliases, getEnvironmentPath } = require('../config/dfx.config.cjs');

test('DFX Config: generateCanisterAliases()', async function (t) {
	const aliases = generateCanisterAliases();

	const expected = {
		'local-canister-ids': '/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json',
		$IDLdsign_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/dsign_assets.did.js',
		$IDLcanister_map:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/canister_map/canister_map.did.js',
		$IDLprofile: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/profile.did.js',
		$IDLprofile_avatar_images:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile_avatar_images/profile_avatar_images.did.js',
		$IDLprofile_avatar_main:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile_avatar_main/profile_avatar_main.did.js',
		$IDLproject_main:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/project_main/project_main.did.js',
		$IDLsnap: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap/snap.did.js',
		$IDLsnap_images:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap_images/snap_images.did.js',
		$IDLsnap_main: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap_main/snap_main.did.js',
		$IDLusername: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/username/username.did.js',
		$IDLlogger: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/logger/logger.did.js'
	};

	t.deepEqual(aliases, expected);
});

test('DFX Config: getEnvironmentPath()', async function (t) {
	const isDevelopment = false;
	const environmentDev = getEnvironmentPath(isDevelopment);
	const environmentProd = getEnvironmentPath(!isDevelopment);

	// TODO: needs to be made dev agnostic
	const expectedDev = '/Users/cyberowl/Projects/dsign/config/env.prod.config.js';
	const expectedProd = '/Users/cyberowl/Projects/dsign/config/env.dev.config.js';

	// dev
	t.equal(environmentDev, expectedDev);

	// prod
	t.equal(environmentProd, expectedProd);
});
