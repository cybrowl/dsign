// import { terser } from 'rollup-plugin-terser';
import { sveltekit } from '@sveltejs/kit/vite';

import { generateCanisterAliases, getEnvironmentPath } from './config/dfx.config.cjs';

const isDevelopment = process.env.DFX_NETWORK !== 'ic';
const isProduction = process.env.DFX_NETWORK === 'ic';

const aliases = generateCanisterAliases();
const environment = getEnvironmentPath(isDevelopment);

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
			environment: envOptions.environment
		},
		dedupe: ['svelte']
	},
	plugins: [sveltekit()]
};

export default config;
