import { describe, it, expect } from 'vitest';
import { generateCanisterAliases, getEnvironmentPath } from '../config/dfx.config.cjs';

describe.concurrent('DFX Config', () => {
	it('generateCanisterAliases()', async () => {
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

		expect(aliases).toEqual(expected);
	});

	it('getEnvironmentPath()', async () => {
		const isDevelopment = false;
		const environmentDev = getEnvironmentPath(isDevelopment);
		const environmentProd = getEnvironmentPath(!isDevelopment);

		const expectedDev = '/Users/cyberowl/Projects/dsign/config/env.prod.config.js';
		const expectedProd = '/Users/cyberowl/Projects/dsign/config/env.dev.config.js';

		// dev
		expect(environmentDev).toBe(expectedDev);

		// prod
		expect(environmentProd).toBe(expectedProd);
	});
});
