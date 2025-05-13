<svelte:head>
	<title>Image Display</title>
	<meta name="description" content="A full-screen image display page" />
</svelte:head>

<main class="container">
	<!-- Image source should be placed in the static folder for SvelteKit projects -->
	<img
		src="/dead_project.png"
		alt="A full-screen display of the Dead Project artwork"
		class="image"
	/>
</main>

<style lang="postcss">
	.container {
		@apply w-screen h-screen flex items-center justify-center overflow-hidden m-0;
	}

	.image {
		@apply w-screen h-screen object-cover absolute top-0 left-0;
	}
</style>
