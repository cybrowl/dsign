<svelte:head>
	<title>DSign</title>
	<meta name="description" content="Dead Project" />
</svelte:head>

<main class="container">
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
