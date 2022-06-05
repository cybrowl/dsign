const http = require('http');
const fs = require('fs');

function callImageCanister(path) {
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

	// covert to unit 8 array
	const mishicat_unit8_array_buffer = new Uint8Array(mishicat_image_buffer);
	const motoko_unit8_array_buffer = new Uint8Array(motoko_image_buffer);

	const images = [[...mishicat_unit8_array_buffer], [...motoko_unit8_array_buffer]];

	return images;
}

module.exports = {
	callImageCanister,
	generate_images
};
