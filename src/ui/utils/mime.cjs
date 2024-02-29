function getMimeType(filePath) {
	const extensionToMimeType = {
		'.txt': 'text/plain',
		'.html': 'text/html',
		'.css': 'text/css',
		'.js': 'application/javascript',
		'.json': 'application/json',
		'.png': 'image/png',
		'.jpg': 'image/jpeg',
		'.jpeg': 'image/jpeg',
		'.gif': 'image/gif'
		// Add more mappings as needed
	};

	// Extract the file extension from the file path
	const extension = filePath.slice(filePath.lastIndexOf('.'));

	// Return the corresponding MIME type or a default/fallback type
	return extensionToMimeType[extension] || 'application/octet-stream';
}

module.exports = { getMimeType };
