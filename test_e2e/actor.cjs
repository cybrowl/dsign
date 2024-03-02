const { HttpAgent, Actor } = require('@dfinity/agent');

const HOST = 'http://127.0.0.1:8080/';

const getActor = async (canisterId, idlFactory, identity) => {
	if (canisterId === undefined) {
		console.log('ERROR: CanisterId: ', canisterId);
		return null;
	}

	if (idlFactory === undefined) {
		console.log('ERROR: idlFactory: ', idlFactory);
		return null;
	}

	if (identity === undefined) {
		console.log('ERROR: identity:', identity);
	}

	const agent = new HttpAgent({
		host: HOST,
		identity: identity
	});

	agent.fetchRootKey().catch((err) => {
		console.warn('Unable to fetch root key. Check to ensure that your local replica is running');
		console.error(err);
	});

	const actor = Actor.createActor(idlFactory, {
		agent: agent,
		canisterId
	});

	return actor;
};

module.exports = {
	getActor
};
