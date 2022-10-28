import preprocess from 'svelte-preprocess';
import tailwind from 'tailwindcss';
import autoprefixer from 'autoprefixer';

import adapter from '@sveltejs/adapter-static';

const config = {
	preprocess: preprocess({
		postcss: {
			plugins: [tailwind, autoprefixer]
		}
	}),

	kit: {
		files: {
			assets: 'src/dsign_assets/assets',
			hooks: 'src/dsign_assets/hooks',
			lib: 'src/dsign_assets/lib',
			routes: 'src/dsign_assets/routes',
			template: 'src/dsign_assets/app.html'
		},
		paths: {
			assets: '',
			base: ''
		},
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: 'index.html',
			precompress: false
		})
	}
};

export default config;
