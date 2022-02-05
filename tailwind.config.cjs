module.exports = {
	content: ['./src/dsign_assets/**/*.{html,js,cjs, svelte}'],
	purge: ['./src/**/*.html', './src/**/*.svelte'],
	darkMode: 'class', // or 'media' or 'class'
	theme: {
		extend: {
			colors: {
				'dark-stone': '#121212'
			}
		}
	},
	variants: {
		extend: {}
	},
	plugins: []
};
