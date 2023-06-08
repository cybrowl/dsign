import canisterIds from '../canister_ids.json';

export default function env() {
	return {
		DFX_NETWORK: 'staging',
		canisterIds
	};
}
