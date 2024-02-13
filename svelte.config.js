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
			assets: 'src/ui/assets',
			lib: 'src/ui/lib',
			routes: 'src/ui/routes',
			appTemplate: 'src/ui/app.html'
		},
		adapter: adapter({
			pages: 'build',
			assets: 'build',
			fallback: 'index.html',
			precompress: true
		})
	}
};

export default config;
