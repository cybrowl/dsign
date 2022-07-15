<script>
	import SnapCreation from 'dsign-components/components/SnapCreation.svelte';
	import get from 'lodash/get.js';
	import Modal from 'dsign-components/components/Modal.svelte';

	import { actor_snap_main, snap_storage } from '../store/actor_snap_main';

	import { isSnapCreationModalVisible } from '../store/modal';

	function handleCloseModal() {
		isSnapCreationModalVisible.update((isSnapCreationModalVisible) => !isSnapCreationModalVisible);
	}

	async function handleSnapCreation(e) {
		const snap = get(e, 'detail');

		const first_image = snap.images.shift();

		const created_snap_res = await $actor_snap_main.actor.create_snap({
			...snap,
			images: [{ data: first_image }]
		});

		const snap_creation_promises = [];

		for (const image of snap.images) {
			snap_creation_promises.push(
				$actor_snap_main.actor.finalize_snap_creation({
					canister_id: created_snap_res.ok.canister_id,
					snap_id: created_snap_res.ok.id,
					images: [{ data: image }]
				})
			);
		}

		Promise.all(snap_creation_promises).then(async () => {
			const all_snaps = await $actor_snap_main.actor.get_all_snaps();

			snap_storage.set({ isFetching: false, ...all_snaps });
		});
	}
</script>

<Modal on:closeModal={handleCloseModal}>
	<SnapCreation on:create_snap={handleSnapCreation} />
</Modal>

<style>
</style>
