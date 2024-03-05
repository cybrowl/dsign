import fs from 'fs';
import path from 'path';
import { getMimeType } from '../../src/ui/utils/mime';

export function createFileObject(filePath) {
	const stats = fs.statSync(filePath); // Get file stats to access modification time
	const buffer = fs.readFileSync(filePath);
	const content = new Uint8Array(buffer);
	return {
		name: path.basename(filePath),
		type: getMimeType(filePath),
		content,
		size: buffer.length, // Size in bytes
		lastModified: stats.mtimeMs // Last modified time in milliseconds
	};
}
