const CRC32 = require('crc-32');
const { Buffer } = require('buffer');

//TODO: This can be refactored into a npm pkg
class FileStorage {
	constructor(actor_) {
		this.actor = actor_;
	}

	validate_file(file) {
		if (file === undefined) {
			throw new Error('file is required');
		}

		if (!(file instanceof Uint8Array)) {
			throw new Error('file must be a Uint8Array');
		}
	}

	async upload_chunk({ chunk, order }) {
		return this.actor.create_chunk(chunk, order);
	}

	async upload_chunk_with_retry({ chunk, order, retries = 3, delay = 1000 }) {
		try {
			return await this.upload_chunk({ chunk, order });
		} catch (error) {
			if (retries > 0) {
				await new Promise((resolve) => setTimeout(resolve, delay));
				return this.upload_chunk_with_retry({
					chunk,
					order,
					retries: retries - 1,
					delay
				});
			} else {
				console.log(`Failed to upload chunk ${order} after multiple retries`);
				throw error;
			}
		}
	}

	update_checksum(chunk, checksum) {
		const moduloValue = 400000000;

		const signedChecksum = CRC32.buf(Buffer.from(chunk), 0);
		const unsignedChecksum = signedChecksum >>> 0;
		const updatedChecksum = (checksum + unsignedChecksum) % moduloValue;

		return updatedChecksum;
	}

	create_upload_promises(file, chunkSize, callback) {
		const promises = [];
		let checksum = 0;

		const totalToStore = file.length;
		var totalStored = 0;

		for (let start = 0, index = 0; start < file.length; start += chunkSize, index++) {
			const chunk = file.slice(start, start + chunkSize);
			checksum = this.update_checksum(chunk, checksum);

			promises.push(
				this.upload_chunk_with_retry({
					chunk,
					order: index
				}).then((promise) => {
					totalStored += chunkSize;
					totalStored = Math.min(totalStored, totalToStore);
					callback(totalStored / totalToStore);
					return promise;
				})
			);
		}

		return { promises, checksum };
	}

	async create_file_from_chunks({
		chunk_ids,
		checksum,
		content_type = 'application/octet-stream',
		filename = 'file'
	}) {
		if (chunk_ids.length < 1) {
			throw new Error('chunk_ids is required');
		}

		const response = await this.actor.create_file_from_chunks(chunk_ids, {
			filename,
			checksum: checksum,
			content_encoding: { Identity: null },
			content_type
		});

		return response;
	}

	// Store File
	async store(file, { content_type, filename }, callback = () => {}) {
		callback(0);
		this.validate_file(file);

		const chunkSize = 2000000;
		const { promises, checksum } = this.create_upload_promises(file, chunkSize, callback);

		const chunk_ids = await Promise.all(promises);

		return await this.create_file_from_chunks({
			chunk_ids,
			checksum,
			content_type,
			filename
		});
	}

	// Get All Files
	async get_all_files() {
		return this.actor.get_all_files();
	}

	// Get File
	async get_file(id) {
		return this.actor.get_file(id);
	}

	// Delete File
	async delete_file(id) {
		return this.actor.delete_file(id);
	}

	// Get Status
	async get_status() {
		return this.actor.get_status();
	}

	// Get Chunks Size
	async chunks_size() {
		return this.actor.chunks_size();
	}

	// Get Version
	async version() {
		return this.actor.version();
	}
}

module.exports = { FileStorage };
