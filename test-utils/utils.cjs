const http = require('http');
const fs = require('fs');

function request_image_canister(path) {
	const options = {
		hostname: '127.0.0.1',
		port: 8000,
		secure: false,
		path: path,
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

	// covert to unit 8 array
	const mishicat_unit8_array_buffer = new Uint8Array(mishicat_image_buffer);
	const motoko_unit8_array_buffer = new Uint8Array(motoko_image_buffer);
	const above_2m_unit8_array_buffer = new Uint8Array(above_2m_image_buffer);
	const nyan_cat_unit8_array_buffer = new Uint8Array(nyan_cat_image_buffer);

	const images = [
		[...mishicat_unit8_array_buffer],
		[...motoko_unit8_array_buffer],
		[...above_2m_unit8_array_buffer],
		[...nyan_cat_unit8_array_buffer]
	];

	return images;
}

function generate_figma_asset() {
	const figma_asset_buffer = fs.readFileSync('test-utils/assets/dsign_stage_1.fig');

	return figma_asset_buffer;
}

module.exports = {
	request_image_canister,
	generate_images,
	generate_figma_asset
};
