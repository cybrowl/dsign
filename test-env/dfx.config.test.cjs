const test = require('tape');
const { generateCanisterAliases, getEnvironmentPath } = require('../config/dfx.config.cjs');

test('DFX Config: generateCanisterAliases()', async function (t) {
	const aliases = generateCanisterAliases();

	const expected = {
		'local-canister-ids': '/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json',
		$IDLdsign_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/dsign_assets.did.js',
		$IDLaccount_settings:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/account_settings/account_settings.did.js',
		$IDLprofile: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/profile.did.js',
		$IDLprofile_avatar:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile_avatar/profile_avatar.did.js',
		$IDLprojects: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/projects/projects.did.js',
		$IDLsnap_main: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap_main/snap_main.did.js',
		$IDLsnap: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap/snap.did.js',
		$IDLsnap_images:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap_images/snap_images.did.js',
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