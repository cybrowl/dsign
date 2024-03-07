import { writable } from 'svelte/store';

const stores = {
	local: {},
	session: {}
};

// Custom serializer for handling BigInt
const bigIntSerializer = {
	stringify(value) {
		return JSON.stringify(value, (_, v) => (typeof v === 'bigint' ? `BigInt(${v.toString()})` : v));
	},
	parse(text) {
		return JSON.parse(text, (_, v) => {
			if (typeof v === 'string' && v.startsWith('BigInt(')) {
				return BigInt(v.slice(7, -1));
			}
			return v;
		});
	}
};

function getStorage(type) {
	return type === 'local' ? localStorage : sessionStorage;
}

export function persisted(key, initialValue, options = {}) {
	const { storage = 'local', syncTabs = true } = options;
	// Use bigIntSerializer as the default serializer
	const serializer = options.serializer || bigIntSerializer;
	const storageObject = getStorage(storage);
	let store = stores[storage][key];

	if (!store) {
		function updateStorage(value) {
			try {
				storageObject.setItem(key, serializer.stringify(value));
			} catch (e) {
				console.error(e);
			}
		}

		function readInitialValue() {
			const storedValue = storageObject.getItem(key);
			return storedValue ? serializer.parse(storedValue) : initialValue;
		}

		const initial = readInitialValue();
		const svelteStore = writable(initial);

		const { subscribe, set, update } = svelteStore;

		store = {
			subscribe,
			set: (value) => {
				set(value);
				updateStorage(value);
			},
			update: (fn) => {
				update((currentValue) => {
					const newValue = fn(currentValue);
					updateStorage(newValue);
					return newValue;
				});
			}
		};

		if (typeof window !== 'undefined' && syncTabs && storage === 'local') {
			window.addEventListener('storage', (event) => {
				if (event.key === key) {
					const newValue = event.newValue ? serializer.parse(event.newValue) : initialValue;
					set(newValue);
				}
			});
		}

		stores[storage][key] = store;
	}

	return store;
}
