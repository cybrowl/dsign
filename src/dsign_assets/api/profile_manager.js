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