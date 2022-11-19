import { modal_visible } from './modal.js';

function change_visibility(name) {
	modal_visible.update((options) => {
		return {
			...options,
			[name]: !options[name]
		};
	});
}

export default {
	change_visibility
};
