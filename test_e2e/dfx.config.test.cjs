const test = require('tape');
const { generateCanisterAliases, getEnvironmentPath } = require('../config/dfx.config.cjs');

test('DFX Config: generateCanisterAliases()', async function (t) {
	const aliases = generateCanisterAliases();

	const expected = {
		'local-canister-ids': '/Users/cyberowl/Projects/dsign/.dfx/local/canister_ids.json',
		$IDLinternet_identity:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/internet_identity/service.did.js',
		$IDLui: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/ui/service.did.js',
		$IDLexplore: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/explore/service.did.js',
		$IDLlogger: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/logger/service.did.js',
		$IDLcreator: '/Users/cyberowl/Projects/dsign/.dfx/local/canisters/creator/service.did.js',
		$IDLusername_registry:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/username_registry/service.did.js',
		$IDLfile_storage:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/file_storage/service.did.js',
		$IDLfile_scaling_manager:
			'/Users/cyberowl/Projects/dsign/.dfx/local/canisters/file_scaling_manager/service.did.js'
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
