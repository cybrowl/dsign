import { error } from '@sveltejs/kit';
import { AuthClient } from '@dfinity/auth-client';
import { createActor as create_actor_profile, actor_profile } from '../../../store/actor_profile';

/** @type {import('./$types').PageLoad} */
export async function load({ params }) {
	console.log('params: ', params);
	let authClient = await AuthClient.create();

	actor_profile.update(() => ({
		loggedIn: true,
		actor: create_actor_profile({
			agentOptions: {
				identity: authClient.getIdentity()
			}
		})
	}));

	actor_profile.subscribe(async (actor_profile) => {
		console.log('actor_profile value', actor_profile);
		let profile_res = await actor_profile.actor.get_profile();

		console.log('profile_res: ', profile_res);
	});

	console.log('actor_profile.actor', actor_profile.actor);

	if (params.slug === 'cyberowl') {
		return {
			title: 'Hello world!',
			content: 'Welcome to our blog. Lorem ipsum dolor sit amet...'
		};
	}

	throw error(404, 'Not found');
}

export const ssr = true;
