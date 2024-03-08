export function extractImages(results) {
	const images = results.map((item) => item.ok);

	return images;
}
