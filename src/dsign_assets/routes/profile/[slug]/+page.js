// import { error } from '@sveltejs/kit';
import { AuthClient } from '@dfinity/auth-client';
import { createActor as create_actor_profile } from '../../../store/actor_profile';

/** @type {import('./$types').PageLoad} */
export async function load({ params }) {
	console.log('params', params);

	let authClient = await AuthClient.create();

	const profile_actor = create_actor_profile({
		agentOptions: {
			identity: authClient.getIdentity()
		}
	});

	let profile_res = await profile_actor.get_profile();

	console.log('profile_res: ', profile_res);

	return {
		username: params.slug,
		profile: profile_res.ok.profile,
		content: 'Welcome to our blog. Lorem ipsum dolor sit amet...'
	};
}

export const ssr = true;
