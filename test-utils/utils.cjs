const http = require('http');
const fs = require('fs');

function extractPath(url) {
	return url.replace('http://localhost:8080', '');
}

function request_resource(url) {
	const options = {
		hostname: '127.0.0.1',
		port: 8080,
		secure: false,
		path: extractPath(url),
		method: 'GET',
		headers: {
			'Content-Type': 'image/png'
		}
	};

	return new Promise(function (resolve, reject) {
		const req = http.request(options, (res) => {
			resolve(res);
		});

		req.on('error', (error) => {
			reject(error);
		});
		req.end();
	});
}

function generate_images() {
	const mishicat_image_buffer = fs.readFileSync('test-utils/images/mishicat.png');
	const motoko_image_buffer = fs.readFileSync('test-utils/images/motoko.png');
	const above_2m_image_buffer = fs.readFileSync('test-utils/images/image_above_2mb.png');
	const nyan_cat_image_buffer = fs.readFileSync('test-utils/images/nyan_cat.gif');
	// const storm_image_buffer = fs.readFileSync('test-utils/images/storm.jpeg');

	// covert to unit 8 array
	const mishicat_unit8_array_buffer = new Uint8Array(mishicat_image_buffer);
	const motoko_unit8_array_buffer = new Uint8Array(motoko_image_buffer);
	const above_2m_unit8_array_buffer = new Uint8Array(above_2m_image_buffer);
	const nyan_cat_unit8_array_buffer = new Uint8Array(nyan_cat_image_buffer);
	// const storm_unit8_array_buffer = new Uint8Array(storm_image_buffer);

	const images = [
		[...mishicat_unit8_array_buffer],
		[...motoko_unit8_array_buffer],
		[...above_2m_unit8_array_buffer],
		[...nyan_cat_unit8_array_buffer]
	];

	return images;
}

function generate_flower_images() {
	const images = [
		[...new Uint8Array(fs.readFileSync('test-utils/images/flowers.webp'))],
		[...new Uint8Array(fs.readFileSync('test-utils/images/lotus.jpeg'))],
		[...new Uint8Array(fs.readFileSync('test-utils/images/tulip.webp'))]
	];

	return images;
}

function generate_animal_images() {
	const images = [
		[...new Uint8Array(fs.readFileSync('test-utils/images/cat.webp'))],
		[...new Uint8Array(fs.readFileSync('test-utils/images/woodpecker.webp'))]
	];

	return images;
}

function generate_motoko_image() {
	const images = [[...new Uint8Array(fs.readFileSync('test-utils/images/motoko.png'))]];

	return images;
}

function generate_figma_asset() {
	const figma_asset_buffer = fs.readFileSync('test-utils/assets/dsign_stage_1.fig');

	return figma_asset_buffer;
}

function generate_figma_dsign_components() {
	const figma_asset_buffer = fs.readFileSync('test-utils/assets/dsign_components.fig');

	return figma_asset_buffer;
}

function generate_large_img_asset() {
	const large_img_asset_buffer = fs.readFileSync('test-utils/images/storm.jpeg');

	return large_img_asset_buffer;
}

module.exports = {
	generate_animal_images,
	generate_figma_asset,
	generate_flower_images,
	generate_images,
	generate_figma_dsign_components,
	generate_large_img_asset,
	generate_motoko_image,
	request_resource
};
