<script>
	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';

	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	page_navigation_update.deselect_all();
</script>

<svelte:head>
	<title>Project</title>
</svelte:head>

<main class="grid grid-cols-12 gap-y-2">
	<div class="col-start-2 col-end-12 mb-24">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>
</main>
