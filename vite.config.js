import { sveltekit } from '@sveltejs/kit/vite';
import { resolve } from 'path';

import { generateCanisterAliases, getEnvironmentPath } from './config/dfx.config.cjs';

const isDevelopment = process.env.DFX_NETWORK !== 'ic' && process.env.DFX_NETWORK !== 'staging';
const isProduction = process.env.DFX_NETWORK === 'ic';
const isStaging = process.env.DFX_NETWORK === 'staging';

const aliases = generateCanisterAliases();
const environment = getEnvironmentPath(isDevelopment, isStaging);

const envOptions = {
	isDevelopment,
	isProduction,
	aliases,
	environment
};

const config = {
	server: {
		fs: {
			allow: ['config', '.dfx/local']
		}
	},
	resolve: {
		alias: {
			...envOptions.aliases,
			$components_ref: resolve('./src/dsign_assets/components/'),
			$modals_ref: resolve('./src/dsign_assets/modals/'),
			$stores_ref: resolve('./src/dsign_assets/store/'),
			$utils: resolve('./src/dsign_assets/utils'),
			environment: envOptions.environment
		},
		dedupe: ['svelte']
	},
	plugins: [sveltekit()]
};

export default config;
