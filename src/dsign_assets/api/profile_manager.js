import { profileManager } from '$ICprofile_manager';

// TODO: catch should log errors to Heartbeat from beta testers
export async function ping() {
	try {
		const response = await profileManager.ping();

		return response;
	} catch (err) {
		console.error(err);
	}
}

export async function create_profile(username) {
	try {
		const response = await profileManager.create_profile(username);

		return response;
	} catch (err) {
		console.error(err);
	}
}