export function getRandomSubsetIds(items, maxItems) {
	// Determine the number of items to select, ensuring it's not greater than the array length or maxItems
	const numItems = Math.min(maxItems, items.length, Math.floor(Math.random() * items.length) + 1);

	// Shuffle the array to randomize which items are selected
	const shuffled = items.sort(() => 0.5 - Math.random());

	// Select a subset of IDs
	const selectedIds = shuffled.slice(0, numItems).map((item) => item.id);

	return selectedIds;
}
