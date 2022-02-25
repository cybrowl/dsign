module.exports = {
	content: ['./src/dsign_assets/**/*.{html,js,cjs, svelte}'],
	purge: ['./src/**/*.html', './src/**/*.svelte'],
	darkMode: 'class', // or 'media' or 'class'
	theme: {
		extend: {
			fontFamily: {
				'sans': ['Roboto', 'sans-serif']
			},
			colors: {
                backdrop: '#1B1A22',
                'black-a': '#212029',
                'dark-grey': '#32313D',
                'smoky-grey': '#454352',
                grey: '#5A5866',
                'castle-grey': '#706E7A',
                'stone-grey': '#85838F',
                'fog-grey': '#9B99A3',
                'mist-grey': '#B1B0B8',
                'moon-grey': '#C6C4CC',
                'light-grey': '#E2E1E6',
                'tulip-purple': '#6259C8',
                'primary-purple': '#7A71DE',
                'light-purple': '#6259C8',
                'bubble-purple': '#B6AFFC',
                'lilalic-purple': '#968CFF'
			}
		}
	},
	variants: {
		extend: {}
	},
	plugins: []
};
