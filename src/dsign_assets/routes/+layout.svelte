<script lang="js">
	import '../app.css';
	import { AuthClient } from '@dfinity/auth-client';
	import { onMount } from 'svelte';

	// actors
	import {
		actor_assets_file_chunks,
		actor_assets_img_staging,
		// actor_explore,
		// actor_favorite_main,
		// actor_profile,
		// actor_project_main,
		// actor_snap_main,
		createActor
	} from '$stores_ref/actors';
	import { auth_client } from '$stores_ref/auth_client';

	onMount(async () => {
		const authClient = await AuthClient.create();
		const isAuthenticated = await authClient.isAuthenticated();

		auth_client.set(authClient);

		if (isAuthenticated) {
			console.log('LAYOUT: isAuthenticated: ', isAuthenticated);

			actor_assets_file_chunks.update(() => ({
				loggedIn: true,
				actor: createActor({
					actor_name: 'assets_file_chunks',
					identity: authClient.getIdentity()
				})
			}));

			actor_assets_img_staging.update(() => ({
				loggedIn: true,
				actor: createActor({
					actor_name: 'assets_img_staging',
					identity: authClient.getIdentity()
				})
			}));

			// actor_explore.update(() => ({
			// 	loggedIn: true,
			// 	actor: createActor({
			// 		actor_name: 'explore',
			// 		identity: authClient.getIdentity()
			// 	})
			// }));

			// actor_favorite_main.update(() => ({
			// 	loggedIn: true,
			// 	actor: createActor({
			// 		actor_name: 'favorite_main',
			// 		identity: authClient.getIdentity()
			// 	})
			// }));

			// actor_profile.update(() => ({
			// 	loggedIn: true,
			// 	actor: createActor({
			// 		actor_name: 'profile',
			// 		identity: authClient.getIdentity()
			// 	})
			// }));

			// actor_project_main.update(() => ({
			// 	loggedIn: true,
			// 	actor: createActor({
			// 		actor_name: 'project_main',
			// 		identity: authClient.getIdentity()
			// 	})
			// }));

			// actor_snap_main.update(() => ({
			// 	loggedIn: true,
			// 	actor: createActor({
			// 		actor_name: 'snap_main',
			// 		identity: authClient.getIdentity()
			// 	})
			// }));
		} else {
			console.log('LAYOUT ERR : isAuthenticated: ', isAuthenticated);
		}
	});
</script>

<slot />

<style lang="postcss">
</style>
