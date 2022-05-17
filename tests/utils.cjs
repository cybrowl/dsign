const http = require('http');

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

module.exports = {
	callImageCanister
}