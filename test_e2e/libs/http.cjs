const http = require('http'); // For HTTP requests. Use 'https' module for secure requests.
const url = require('url'); // To parse URLs.

/**
 * Sends a GET request to a specified URL to request a resource.
 * Automatically determines the protocol (HTTP/HTTPS) based on the URL.
 *
 * @param {string} resourceUrl - The complete URL of the resource to fetch.
 * @returns {Promise} - A promise that resolves with the response object or rejects with an error.
 */
function requestResource(resourceUrl) {
	// Parse the input URL to extract components.
	const parsedUrl = new URL(resourceUrl);

	// Determine the appropriate module (http or https) based on the protocol.
	const protocol = parsedUrl.protocol === 'https:' ? require('https') : http;

	// Configure request options based on parsed URL.
	const options = {
		hostname: parsedUrl.hostname,
		port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 8080), // Default ports for HTTP (8080) and HTTPS (443).
		path: parsedUrl.pathname + parsedUrl.search, // Include query string if present.
		method: 'GET',
		headers: {
			Accept: 'image/png' // Expecting an image/png response. Modify as needed.
		}
	};

	return new Promise((resolve, reject) => {
		const req = protocol.request(options, (res) => {
			// Handle HTTP status codes here if needed.
			if (res.statusCode < 200 || res.statusCode >= 300) {
				return reject(new Error(`HTTP status code ${res.statusCode}`));
			}

			resolve(res);
		});

		req.on('error', (error) => {
			reject(error);
		});

		req.end();
	});
}

module.exports = {
	requestResource
};
