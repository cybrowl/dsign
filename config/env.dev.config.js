import canisterIds from 'local-canister-ids';

export default function env() {
	return {
		DFX_NETWORK: 'local',
		canisterIds
	};
}
