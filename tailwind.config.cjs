module.exports = {
	mode: 'jit',
	content: ['./src/ui/**/*.svelte', './src/**/*.{html,js}'],
	darkMode: 'class', // or 'media' or 'class'
	theme: {
		extend: {
			fontFamily: {
				sans: ['Roboto', 'sans-serif']
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
				'cloud-purple': '#EBE9FF',
				'primary-purple': '#7A71DE',
				'foggy-purple': '#A099F4',
				'bubble-purple': '#B6AFFC',
				'lilalic-purple': '#968CFF',
				'spring-leaf-green': '#5BC859',
				'error-red': '#FC3030',
				'reject-red': '#FFA1B2',
				'mute-red': '#F0627C',
				'warning-yellow': '#FFF0A1',
				'ghost-white': '#FEFEFF'
			},
			boxShadow: {
				gray: '0 10px 15px -3px rgba(58, 58, 80, 0.5), 0 4px 6px -2px rgba(58, 58, 80, 0.3)'
			},
			screens: {
				'3xl': '2222px'
			}
		}
	},
	variants: {
		extend: {}
	},
	plugins: []
};
