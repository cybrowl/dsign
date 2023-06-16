const test = require('tape');
const { generateCanisterAliases, getEnvironmentPath } = require('../config/dfx.config.cjs');

test('DFX Config: generateCanisterAliases()', async function (t) {
	const aliases = generateCanisterAliases();

	const expected = {
		'local-canister-ids': '/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json',
		$IDLdsign_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/dsign_assets/service.did.js',
		$IDLassets_file_staging:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/assets_file_staging/service.did.js',
		$IDLassets_img_staging:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/assets_img_staging/service.did.js',
		$IDLcanister_ids_ledger:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/canister_ids_ledger/service.did.js',
		$IDLexplore: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/explore/service.did.js',
		$IDLfavorite_main:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/favorite_main/service.did.js',
		$IDLhealth_metrics:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/health_metrics/service.did.js',
		$IDLprofile: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/profile/service.did.js',
		$IDLproject_main:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/project_main/service.did.js',
		$IDLsnap_main: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/snap_main/service.did.js',
		$IDLlogger: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/logger/service.did.js',
		$IDLtest_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/test_assets/service.did.js',
		$IDLtest_favorite:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/test_favorite/service.did.js',
		$IDLtest_image_assets:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/test_image_assets/service.did.js',
		$IDLtest_project:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/test_project/service.did.js',
		$IDLtest_snap: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/test_snap/service.did.js'
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
