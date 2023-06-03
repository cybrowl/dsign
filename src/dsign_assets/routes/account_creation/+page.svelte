<script>
	import { goto } from '$app/navigation';

	import Login from '../../components/Login.svelte';
	import { PageNavigation } from 'dsign-components';
	import AccountCreationModal from '../../modals/AccountCreationModal.svelte';

	import { page_navigation } from '$stores_ref/page_navigation';
</script>

<svelte:head>
	<title>Account Creation</title>
</svelte:head>

<main class="grid_layout">
	<div class="navigation_main_layout">
		<PageNavigation
			navigationItems={$page_navigation.navigationItems}
			on:home={() => {
				goto('/');
			}}
		>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountCreationModal -->
	<AccountCreationModal />

	<div class="h-screen" />
</main>

<!-- Mobile Not Supported -->
<div class="not_supported">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style lang="postcss">
	.grid_layout {
		@apply grid grid-cols-12 gap-y-2;
	}
	.navigation_main_layout {
		@apply col-start-2 col-end-12 mb-24;
	}
	.not_supported {
		@apply grid lg:hidden h-screen place-items-center text-white text-4xl;
	}
</style>
