const dfxConfig = require('../dfx.json');

function generateCanisterAliases() {
	const dfxNetwork = process.env['DFX_NETWORK'] || 'local';
	const rootPath = __dirname.split('/config')[0];

	let aliases = {
		['local-canister-ids']: ''.concat(
			rootPath,
			'/',
			'.dfx',
			'/',
			dfxNetwork,
			'/',
			'canister_ids.json'
		)
	};

	if (dfxConfig.canisters) {
		const listOfCanisterNames = Object.keys(dfxConfig.canisters);

		aliases = listOfCanisterNames.reduce((acc, name) => {
			const outputRoot = ''.concat(
				rootPath,
				'/',
				'.dfx',
				'/',
				dfxNetwork,
				'/',
				'canisters',
				'/',
				name
			);

			return {
				...acc,
				['$IDL' + name]: ''.concat(outputRoot + '/' + 'service.did.js')
			};
		}, aliases);
	}

	return aliases;
}

function getEnvironmentPath(isDevelopment, isStaging) {
	if (isDevelopment) {
		return ''.concat(__dirname, '/', 'env.dev.config.js');
	} else if (isStaging) {
		return ''.concat(__dirname, '/', 'env.staging.config.js');
	} else {
		return ''.concat(__dirname, '/', 'env.prod.config.js');
	}
}

module.exports = {
	generateCanisterAliases,
	getEnvironmentPath
};
