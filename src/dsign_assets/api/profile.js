import { profile } from '$ICprofile';

// TODO: catch should log errors to Heartbeat from beta testers
export async function ping() {
	try {
		const response = await profile.ping();

		return response;
	} catch (err) {
		console.error(err);
	}
}

export async function get_canister_caller_principal() {
	try {
		const response = await profile.get_canister_caller_principal();

		return response;
	} catch (err) {
		console.error(err);
	}
}
