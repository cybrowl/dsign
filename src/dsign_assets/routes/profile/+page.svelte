<script>
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import get from 'lodash/get';
	import { AuthClient } from '@dfinity/auth-client';

	// actors
	import { actor_profile } from '../../store/actors';

	// local storage
	import { local_storage_profile } from '../../store/local_storage';

	import { page_navigation } from '../../store/page_navigation';

	import Login from '../../components/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';

	const username = get($local_storage_profile, 'username', '');

	if (username.length > 0) {
		goto(`/profile/${username}`);
	}

	onMount(async () => {
		let authClient = await AuthClient.create();
		let isAuthenticated = await authClient.isAuthenticated();

		page_navigation.update(({ navItems }) => {
			navItems.forEach((navItem) => {
				navItem.isSelected = false;
			});
			navItems[3].isSelected = true;

			return {
				navItems: navItems
			};
		});

		try {
			if (isAuthenticated) {
				let { ok: profile, err: error } = await $actor_profile.actor.get_profile();
				const username = get(profile, 'profile.username', 'x');

				goto(`/profile/${username}`);
			}
		} catch (error) {
			console.log('error', error);
		}
	});
</script>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>
</main>
