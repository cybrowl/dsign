import { terser } from 'rollup-plugin-terser';
import adapter from '@sveltejs/adapter-static';
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
	kit: {
		files: {
			assets: 'src/dsign_assets/assets',
			hooks: 'src/dsign_assets/hooks',
			lib: 'src/dsign_assets/lib',
			routes: 'src/dsign_assets/routes',
			template: 'src/dsign_assets/app.html'
		},
		adapter: adapter({ pages: 'build', fallback: 'index.html' }),
		vite: viteConfig(envOptions)
	}
};

function viteConfig(envOptions) {
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
		plugins: [envOptions.isProduction && terser()]
	};

	return config;
}
export default config;
