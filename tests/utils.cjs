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

function generateImages() {
	const mishicatImageBuffer = fs.readFileSync('tests/images/mishicat.png');
	const motokoImageBuffer = fs.readFileSync('tests/images/motoko.png');

	// covert to unit 8 array
	const mishicatUnit8ArrayBuffer = new Uint8Array(mishicatImageBuffer);
	const motokoUnit8ArrayBuffer = new Uint8Array(motokoImageBuffer);

	const images = [[...mishicatUnit8ArrayBuffer], [...motokoUnit8ArrayBuffer]];

	return images;
}

module.exports = {
	callImageCanister,
	generateImages
};
