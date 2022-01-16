import { terser } from 'rollup-plugin-terser';
import sveltePreprocess from 'svelte-preprocess';
import svelte from 'rollup-plugin-svelte';
import { generateCanisterAliases, getEnvironmentPath } from './config/dfx.config.cjs';
import { defineConfig } from 'vite';
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
		package: {
			dir: 'public'
		},
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
		target: '#dsign-root'
	},
	preprocess: sveltePreprocess(preprocessOptions, preprocessOptions),
	vite: viteConfig(envOptions, preprocessOptions)
};

function viteConfig(envOptions, preprocessOptions) {
	const config = defineConfig({
		resolve: {
			alias: {
				...envOptions.aliases,
				environment: envOptions.environment
			},
			dedupe: ['svelte']
		},
		plugins: [
			// alias({
			// 	entries: {
			// 		...envOptions.aliases,
			// 		environment: envOptions.environment
			// 	}
			// }),
			// commonjs(),
			svelte({
				compilerOptions: {
					dev: envOptions.isDevelopment
				},
				preprocess: sveltePreprocess({
					...preprocessOptions,
					sourceMap: envOptions.isDevelopment
				})
			}),
			envOptions.isProduction && terser()
		]
	});

	console.log('config: ', config);

	return config;
}
export default config;
