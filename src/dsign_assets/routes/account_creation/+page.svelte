<!-- src/routes/account_creation.svelte -->
<script>
	import { onMount } from 'svelte';
	import { AuthClient } from '@dfinity/auth-client';

	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import Login from '../../components/Login.svelte';

	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';

	import { page_navigation } from '$stores_ref/page_navigation';
	import {
		actor_profile,
		actor_project_main,
		actor_snap_main,
		createActor
	} from '$stores_ref/actors';

	onMount(async () => {
		let authClient = await AuthClient.create();

		const isAuthenticated = await authClient.isAuthenticated();

		if (isAuthenticated) {
			actor_profile.update(() => ({
				loggedIn: true,
				actor: createActor({
					actor_name: 'profile',
					identity: authClient.getIdentity()
				})
			}));

			actor_project_main.update(() => ({
				loggedIn: true,
				actor: createActor({
					actor_name: 'project_main',
					identity: authClient.getIdentity()
				})
			}));

			actor_snap_main.update(() => ({
				loggedIn: true,
				actor: createActor({
					actor_name: 'snap_main',
					identity: authClient.getIdentity()
				})
			}));
		}
	});
</script>

<svelte:head>
	<title>Account Creation</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	<AccountCreationModal />

	<div class="h-screen" />
</main>

<style>
</style>
