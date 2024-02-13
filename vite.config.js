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
	build: {
		brotliSize: true,
		cssCodeSplit: true,
		minify: isProduction
	},
	server: {
		fs: {
			allow: ['config', '.dfx/local']
		}
	},
	resolve: {
		alias: {
			...envOptions.aliases,
			$components_ref: resolve('./src/ui/components/'),
			$modals_ref: resolve('./src/ui/modals/'),
			$stores_ref: resolve('./src/ui/store/'),
			$utils: resolve('./src/ui/utils'),
			environment: envOptions.environment
		},
		dedupe: ['svelte']
	},
	plugins: [sveltekit()]
};

export default config;
