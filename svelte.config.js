import { terser } from 'rollup-plugin-terser';
import sveltePreprocess from 'svelte-preprocess';
import { generateCanisterAliases, getEnvironmentPath } from './config/dfx.config.cjs';
import adapter from '@sveltejs/adapter-static';

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

const preprocessOptions = {
	sourceMap: true,
	defaults: {
		script: 'javascript',
		style: 'postcss'
	}
};

const config = {
	kit: {
		files: {
			assets: 'src/dsign_assets/assets',
			hooks: 'src/dsign_assets/hooks',
			lib: 'src/dsign_assets/lib',
			routes: 'src/dsign_assets/routes',
			serviceWorker: 'src/dsign_assets/service-worker',
			template: 'src/dsign_assets/app.html'
		},
		adapter: adapter({ pages: 'build', assets: 'build' }),

		// hydrate the <div id="dsign-root"> element in src/app.html
		target: '#dsign-root',
		vite: viteConfig(envOptions)
	},
	preprocess: sveltePreprocess(preprocessOptions)
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
