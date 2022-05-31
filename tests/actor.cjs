const { HttpAgent, Actor } = require('@dfinity/agent');

const HOST = 'http://127.0.0.1:8000/';

const getActor = async (canisterId, idlFactory, identity) => {
	if (canisterId === undefined) {
		console.err('provide canisterId');
		return null;
	}

	if (idlFactory === undefined) {
		console.err('provide idlFactory');
		return null;
	}

	if (identity === undefined) {
		console.err('provide identity');
		return null;
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
