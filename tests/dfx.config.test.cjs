const test = require('tape');
const { generateCanisterAliases, getEnvironmentPath } = require('../config/dfx.config.cjs');

const filename = 'dfx.Config';

test(`${filename}: generateCanisterAliases()`, async function (t) {
	const aliases = generateCanisterAliases();

	const expected = {
		'local-canister-ids': '/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json',
		$ICdsign_assets: '/Users/cyberowl/Projects/dsign/config/declarations/dsign_assets.js',
		$IDLdsign_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/dsign_assets.did.js',
		$ICprofile: '/Users/cyberowl/Projects/dsign/config/declarations/profile.js',
		$IDLprofile: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/profile.did.js',
		$ICprofile_manager: '/Users/cyberowl/Projects/dsign/config/declarations/profile_manager.js',
		$IDLprofile_manager:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile_manager/profile_manager.did.js',
		$IClogger: '/Users/cyberowl/Projects/dsign/config/declarations/logger.js',
		$IDLlogger: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/logger/logger.did.js'
	};

	t.deepEqual(aliases, expected);
});

test(`${filename}: getEnvironmentPath()`, async function (t) {
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