<script>
	import ModalFull from 'dsign-components/components/ModalFull.svelte';
	import SnapPreview from 'dsign-components/components/SnapPreview.svelte';

	import modal_update from '$stores_ref/modal';

	export let snap = {};

	function handleCloseModal() {
		modal_update.change_visibility('snap_preview');
	}
</script>

<ModalFull on:closeModal={handleCloseModal}>
	<SnapPreview {snap} />
</ModalFull>

<style>
</style>
