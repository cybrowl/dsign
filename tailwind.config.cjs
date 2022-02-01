module.exports = {
	content: ['./src/dsign_assets/**/*.{html,js,cjs, svelte}'],
	purge: ['./src/**/*.html', './src/**/*.svelte'],
	darkMode: 'class', // or 'media' or 'class'
	theme: {
		extend: {}
	},
	variants: {
		extend: {}
	},
	plugins: []
};
