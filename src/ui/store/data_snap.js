import { writable } from 'svelte/store';

// Definition of an empty snapshot object
const empty_snap = {
	id: '',
	created: 0n,
	design_file: [],
	username: '',
	image_cover_location: 0,
	metrics: {
		views: 0n,
		likes: 0n
	},
	owner: [],
	name: '',
	tags: [],
	canister_id: '',
	updated: 0n,
	project_id: '',
	images: []
};

// Definition of an empty project object
const empty_project = {};

// Writable store for snap upsert with added 'mode' field
export const snap_upsert_store = writable({
	isFetching: false,
	mode: 'create',
	snap: empty_snap
});

// Writable store for snap project
export const snap_project_store = writable({ isFetching: false, project: empty_project });

export const add_images_to_snap = function (newImages) {
	snap_upsert_store.update((store) => {
		// Map over newImages to add a status of 'new'
		const imagesWithStatus = newImages.map((image) => ({ ...image, status: 'new' }));
		const updatedSnap = { ...store.snap, images: [...store.snap.images, ...imagesWithStatus] };
		return { ...store, snap: updatedSnap };
	});
};

// Function to remove an image from the snap by its ID
export const remove_image_from_snap = function (imageId) {
	snap_upsert_store.update((store) => {
		// Find the image and update its status to 'removed'
		const updatedImages = store.snap.images.map((image) =>
			image.id === imageId ? { ...image, status: 'removed' } : image
		);
		const updatedSnap = { ...store.snap, images: updatedImages };
		return { ...store, snap: updatedSnap };
	});
};

// Function to replace the design file in the snap
export const replace_design_file = function (newDesignFile) {
	snap_upsert_store.update(({ isFetching, mode, snap }) => {
		return {
			isFetching,
			mode,
			snap: {
				...snap,
				design_file: [newDesignFile]
			}
		};
	});
};

// Function to remove the design file from the snap
export const remove_design_file = function () {
	snap_upsert_store.update(({ isFetching, mode, snap }) => {
		return {
			isFetching,
			mode,
			snap: {
				...snap,
				design_file: [] // Set the design_file array to empty
			}
		};
	});
};

// Function to set a specific image as the cover image of the snap by its index
export const select_cover_image = function (imageIndex) {
	snap_upsert_store.update(({ isFetching, mode, snap }) => {
		if (imageIndex >= 0 && imageIndex < snap.images.length) {
			return {
				isFetching,
				mode,
				snap: {
					...snap,
					image_cover_location: imageIndex
				}
			};
		} else {
			console.warn('Selected image index is out of bounds.');
			return { isFetching, mode, snap };
		}
	});
};

// Object to export the functions for manipulating the snap
export const snap_actions = {
	add_images_to_snap,
	remove_image_from_snap,
	replace_design_file,
	remove_design_file,
	select_cover_image
};
