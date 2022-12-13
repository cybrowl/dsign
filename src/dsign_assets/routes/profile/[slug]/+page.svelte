<script>
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import get from 'lodash/get';

	import Login from '$components_ref/Login.svelte';
	import PageNavigation from 'dsign-components/components/PageNavigation.svelte';
	import ProfileBanner from 'dsign-components/components/ProfileBanner.svelte';
	import ProfileInfo from 'dsign-components/components/ProfileInfo.svelte';
	import ProfileTabs from 'dsign-components/components/ProfileTabs.svelte';
	import ProjectCard from 'dsign-components/components/ProjectCard.svelte';
	import ProjectPublicEmpty from 'dsign-components/components/ProjectPublicEmpty.svelte';
	import SnapCard from 'dsign-components/components/SnapCard.svelte';

	import AccountSettingsModal from '$modals_ref/AccountSettingsModal.svelte';
	import SnapCreationModal from '$modals_ref/SnapCreationModal.svelte';

	import { actor_assets_img_staging, actor_profile, actor_project_main } from '$stores_ref/actors';
	import { auth_assets_img_staging, auth_profile } from '$stores_ref/auth_client';
	import { profile_tabs } from '$stores_ref/page_state';
	import {
		project_store_public,
		project_store_public_fetching,
		projects_update
	} from '$stores_ref/fetch_store';
	import modal_update, { modal_visible } from '$stores_ref/modal';
	import page_navigation_update, { page_navigation } from '$stores_ref/page_navigation';

	let project = {
		name: ''
	};
	let isProfileOwner = false;
	let profile = {};

	page_navigation_update.select_item(3);

	if ($project_store_public.projects.length === 0) {
		project_store_public_fetching();
	}

	onMount(async () => {
		await Promise.all([auth_assets_img_staging(), auth_profile()]);

		try {
			const { ok: profile_, err: err_profile } = await $actor_profile.actor.get_profile_public(
				$page.params.slug
			);
			profile = profile_;

			if ($actor_profile.loggedIn) {
				const { ok: profile_, err: err_profile } = await $actor_profile.actor.get_profile();
				const username = get(profile_, 'username', 'x');

				isProfileOwner = username === $page.params.slug;
			}

			const { ok: all_projects, err: err_all_projects } =
				await $actor_project_main.actor.get_all_projects([$page.params.slug]);

			if (all_projects) {
				projects_update.update_projects_public(all_projects);
			} else {
				projects_update.update_projects_public([]);
			}
		} catch (error) {
			// Show error notification
			// TODO: log error
		}
	});

	onDestroy(() => {
		projects_update.update_projects_public([]);
		profile_tabs.set({
			isProjectsSelected: true,
			isProjectSelected: false
		});
	});

	function openAccountSettingsModal() {
		if (isProfileOwner) {
			modal_update.change_visibility('account_settings');
		}
	}

	function handleProjectClick(e) {
		project = get(e, 'detail');

		project.name = project.name.charAt(0).toUpperCase() + project.name.slice(1);

		profile_tabs.set({
			isProjectsSelected: false,
			isProjectSelected: true
		});
	}

	async function handleProfileBannerChange(event) {
		let files = event.detail;

		if ($actor_assets_img_staging.loggedIn && $actor_profile.loggedIn) {
			const selectedFile = files[0];

			const imageAsUnit8ArrayBuffer = new Uint8Array(await selectedFile.arrayBuffer());
			const create_asset_args = {
				data: [...imageAsUnit8ArrayBuffer],
				file_format: selectedFile.type
			};

			try {
				let img_asset_id = await $actor_assets_img_staging.actor.create_asset(create_asset_args);
				const { ok: update_profie, err: err_update_profile_banner } =
					await $actor_profile.actor.update_profile_banner([img_asset_id]);

				let { ok: profile_ } = await $actor_profile.actor.get_profile();

				const randomNumber = Math.floor(Math.random() * 1000);
				profile = profile_;
				profile.banner.url = profile_.banner.url + '&' + randomNumber;
			} catch (error) {
				console.log('error', error);
			}
		}
	}
</script>

<svelte:head>
	<title>Profile</title>
</svelte:head>

<main class="hidden lg:grid grid-cols-12 gap-y-2 relative">
	<div class="col-start-2 col-end-12 row-start-1 row-end-2">
		<PageNavigation navItems={$page_navigation.navItems}>
			<Login />
		</PageNavigation>
	</div>

	<!-- AccountSettingsModal -->
	{#if $modal_visible.account_settings}
		<AccountSettingsModal />
	{/if}

	<!-- SnapCreationModal -->
	{#if $modal_visible.snap_creation}
		<SnapCreationModal />
	{/if}

	<!-- ProfileInfo -->
	<div class="relative col-start-2 col-end-4 row-start-2 row-end-3">
		<ProfileInfo
			avatar={get(profile, 'avatar.url', '')}
			is_authenticated={isProfileOwner}
			username={get(profile, 'username', '')}
			on:editProfile={openAccountSettingsModal}
		/>
	</div>

	<!-- ProfileBanner -->
	<div class="col-start-4 col-end-12 row-start-2 row-end-3">
		<ProfileBanner
			is_authenticated={isProfileOwner}
			profile_banner_url={get(profile, 'banner.url', '')}
			on:profileBannerChange={handleProfileBannerChange}
		/>
	</div>

	<!-- ProfileTabs -->
	<div
		class="hidden lg:grid col-start-4 col-end-12 row-start-3 row-end-4 mt-16
			self-end justify-between items-center h-10"
	>
		<ProfileTabs
			project_name={project.name}
			profileTabs={$profile_tabs}
			on:toggleProjects={(e) => profile_tabs.set(e.detail)}
		/>
	</div>

	<!-- Projects -->
	{#if $profile_tabs.isProjectsSelected}
		<!-- Fetching Projects -->
		{#if $project_store_public.isFetching === true}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				<ProjectCard isLoadingProject={true} />
			</div>
		{/if}

		<!-- No Projects Found -->
		{#if $project_store_public.projects.length === 0 && $project_store_public.isFetching === false}
			<div
				class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
				row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				<ProjectPublicEmpty />
			</div>
		{/if}

		<!-- Project -->
		<div
			class="hidden lg:grid col-start-4 col-end-12 grid-cols-4 
			row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
		>
			{#each $project_store_public.projects as project}
				<ProjectCard {project} on:clickProject={handleProjectClick} />
			{/each}
		</div>
	{/if}

	<!-- Project -->
	{#if $profile_tabs.isProjectSelected}
		<!-- Snaps -->
		{#if project.snaps && project.snaps.length > 0}
			<div
				class="col-start-4 col-end-12 grid grid-cols-4 
						row-start-5 row-end-auto gap-x-8 gap-y-12 mt-2 mb-24"
			>
				{#each project.snaps as snap}
					<SnapCard {snap} />
				{/each}
			</div>
		{/if}
	{/if}
</main>

<!-- Mobile Not Supported -->
<div class="grid lg:hidden h-screen place-items-center text-white text-4xl">
	<h1>Sorry, Mobile Not Supported</h1>
</div>

<style>
</style>
