const getMimeType = (filePath) => {
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

	const extension = filePath.slice(filePath.lastIndexOf('.'));
	return extensionToMimeType[extension] || 'application/octet-stream';
};

export { getMimeType };
