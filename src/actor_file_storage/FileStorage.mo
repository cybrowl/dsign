import Blob "mo:base/Blob";
import { Buffer; toArray } "mo:base/Buffer";
import Error "mo:base/Error";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";

import { ofBlob } "./CRC32";

import Types "./types";

import Utils "./utils";

actor class FileStorage(is_prod : Bool, port : Text) = this {
	let { thash; nhash } = Map;

	type Chunk_ID = Types.Chunk_ID;
	type ChunkInfo = Types.ChunkInfo;
	type CreateStrategyArgs = Types.CreateStrategyArgs;
	type ErrCreateFile = Types.ErrCreateFile;
	type ErrDeleteFile = Types.ErrDeleteFile;
	type File = Types.File;
	type File_ID = Types.File_ID;
	type FileChunk = Types.FileChunk;
	type FileProperties = Types.FileProperties;
	type FilePublic = Types.FilePublic;
	type HttpRequest = Types.HttpRequest;
	type HttpResponse = Types.HttpResponse;
	type Status = Types.Status;
	type StreamingCallbackHttpResponse = Types.StreamingCallbackHttpResponse;
	type StreamingCallbackToken = Types.StreamingCallbackToken;
	type StreamingStrategy = Types.StreamingStrategy;

	// ------------------------- Variables -------------------------
	let ACTOR_NAME : Text = "FileStorage";
	let VERSION : Nat = 1;
	stable var timer_id : Nat = 0;
	private var chunk_id_count : Chunk_ID = 0;

	// ------------------------- Storage Data -------------------------
	private var chunks = Map.new<Chunk_ID, FileChunk>();
	stable var chunks_stable_storage : [(Chunk_ID, FileChunk)] = [];

	private var files = Map.new<File_ID, File>();
	stable var files_stable_storage : [(File_ID, File)] = [];

	// ------------------------- Files -------------------------
	public shared ({ caller }) func create_chunk(content : Blob, order : Nat) : async Nat {
		chunk_id_count := chunk_id_count + 1;

		let checksum = Nat32.toNat(ofBlob(content));

		let file_chunk : FileChunk = {
			checksum = checksum;
			content = content;
			created = Time.now();
			filename = "";
			id = chunk_id_count;
			order = order;
			owner = caller;
		};

		ignore Map.put(chunks, nhash, chunk_id_count, file_chunk);

		return chunk_id_count;
	};

	public shared ({ caller }) func create_file_from_chunks(chunk_ids : [Nat], properties : FileProperties) : async Result.Result<FilePublic, ErrCreateFile> {
		let file_id = Utils.generate_uuid();
		let canister_id = Principal.toText(Principal.fromActor(this));

		var chunks_to_commit = Buffer<ChunkInfo>(0);

		// Collect chunks
		for (id in chunk_ids.vals()) {
			switch (Map.get(chunks, nhash, id)) {
				case (?chunk) {
					chunks_to_commit.add({ id = id; order = chunk.order });
				};
				case (_) {
					return #err(#ChunkNotFound(true));
				};
			};
		};

		// Sort chunks by order
		chunks_to_commit.sort(Utils.compare);

		let modulo_value : Nat = 400_000_000;
		var file_content = Buffer<Blob>(0);
		var file_checksum : Nat = 0;
		var content_size = 0;

		// Accumulate content and compute checksum
		for (chunk_info in chunks_to_commit.vals()) {
			switch (Map.get(chunks, nhash, chunk_info.id)) {
				case (?chunk) {
					if (chunk.owner != caller) {
						return #err(#ChunkOwnerInvalid(true));
					} else {
						file_content.add(chunk.content);
						file_checksum := (file_checksum + chunk.checksum) % modulo_value;
						content_size := content_size + chunk.content.size();
					};
				};
				case (_) {
					return #err(#ChunkNotFound(true));
				};
			};
		};

		// Verify checksum
		if (Nat.notEqual(file_checksum, properties.checksum)) {
			return #err(#ChecksumInvalid(true));
		};

		// Remove committed chunks
		for (id in chunk_ids.vals()) {
			Map.delete(chunks, nhash, id);
		};

		// Create and insert new file
		let file : File = {
			canister_id = canister_id;
			chunks_size = file_content.size();
			content = Option.make(toArray(file_content));
			content_encoding = properties.content_encoding;
			content_size = content_size;
			content_type = properties.content_type;
			created = Time.now();
			filename = properties.filename;
			id = file_id;
			url = Utils.generate_file_url({
				file_id = file_id;
				canister_id = canister_id;
				is_prod = is_prod;
				port = port;
			});
			owner = Principal.toText(caller);
		};

		ignore Map.put(files, thash, file_id, file);

		let file_public : FilePublic = {
			canister_id = canister_id;
			chunks_size = file_content.size();
			content_encoding = properties.content_encoding;
			content_size = content_size;
			content_type = properties.content_type;
			filename = properties.filename;
			id = file_id;
			url = Utils.generate_file_url({
				file_id = file_id;
				canister_id = canister_id;
				is_prod = is_prod;
				port = port;
			});
		};

		return #ok(file_public);
	};

	public shared ({ caller }) func delete_file(id : File_ID) : async Result.Result<Text, ErrDeleteFile> {
		switch (Map.get(files, thash, id)) {
			case (?file) {
				if (file.owner == Principal.toText(caller)) {
					Map.delete(files, thash, id);

					return #ok("Deleted File");
				} else {
					return #err(#NotAuthorized(true));
				};
			};
			case (_) {
				return #err(#FileNotFound(true));
			};
		};
	};

	public query func get_all_files() : async [File] {
		var files_updated = Buffer<File>(0);

		for (file in Map.vals(files)) {
			let file_without_content : File = {
				file with content = null;
			};

			files_updated.add(file_without_content);
		};

		return toArray(files_updated);
	};

	public query func get_file(id : File_ID) : async Result.Result<File, Text> {
		switch (Map.get(files, thash, id)) {
			case (?file) {
				let file_without_content : File = {
					file with content = null;
				};

				return #ok(file_without_content);
			};
			case (_) {
				return #err("File Not Found");
			};
		};
	};

	public query func get_status() : async Status {
		let status : Status = {
			cycles = Utils.get_cycles_balance();
			memory_mb = Utils.get_memory_in_mb();
			heap_mb = Utils.get_heap_in_mb();
			files_size = Map.size(files);
		};

		return status;
	};

	public query func chunks_size() : async Nat {
		return Map.size(chunks);
	};

	public query func is_full() : async Bool {
		let MAX_SIZE_THRESHOLD_MB : Float = 1500;

		let rts_memory_size : Nat = Prim.rts_memory_size();
		let mem_size : Float = Float.fromInt(rts_memory_size);
		let memory_in_megabytes = Float.abs(mem_size * 0.000001);

		if (memory_in_megabytes > MAX_SIZE_THRESHOLD_MB) {
			return true;
		} else {
			return false;
		};
	};

	// ------------------------- Get File HTTP -------------------------
	public shared query ({ caller }) func http_request(request : HttpRequest) : async HttpResponse {
		let NOT_FOUND : [Nat8] = Blob.toArray(Text.encodeUtf8("File Not Found"));

		let file_id = Utils.get_file_id(request.url);

		switch (Map.get(files, thash, file_id)) {
			case (?file) {
				let filename = Text.concat("attachment; filename=", file.filename);

				return {
					body = Blob.toArray(Option.get(file.content, [])[0]);
					headers = [
						("Content-Type", file.content_type),
						("accept-ranges", "bytes"),
						("Content-Disposition", filename),
						("cache-control", "private, max-age=0")
					];
					status_code = 200;
					streaming_strategy = create_strategy({
						file_id = file_id;
						chunk_index = 0;
						data_chunks_size = file.chunks_size;
					});
				};
			};
			case _ {
				return {
					body = NOT_FOUND;
					headers = [];
					status_code = 404;
					streaming_strategy = null;
				};
			};
		};
	};

	private func create_strategy(args : CreateStrategyArgs) : ?StreamingStrategy {
		switch (create_token(args)) {
			case (null) { null };
			case (?token) {
				let self = Principal.fromActor(this);
				let canister_id : Text = Principal.toText(self);
				let canister = actor (canister_id) : actor {
					http_request_streaming_callback : shared () -> async ();
				};

				return ? #Callback({
					token;
					callback = canister.http_request_streaming_callback;
				});
			};
		};
	};

	private func create_token(args : CreateStrategyArgs) : ?StreamingCallbackToken {
		if (args.chunk_index + 1 >= args.data_chunks_size) {
			return null;
		} else {
			let token = {
				file_id = args.file_id;
				chunk_index = args.chunk_index + 1;
				content_encoding = "gzip";
			};

			return ?token;
		};
	};

	public shared query ({ caller }) func http_request_streaming_callback(
		st : StreamingCallbackToken
	) : async StreamingCallbackHttpResponse {
		switch (Map.get(files, thash, st.file_id)) {
			case (null) throw Error.reject("file_id not found: " # st.file_id);
			case (?file) {
				return {
					token = create_token({
						file_id = st.file_id;
						chunk_index = st.chunk_index;
						data_chunks_size = file.chunks_size;
					});
					body = Option.get(file.content, [])[st.chunk_index];
				};
			};
		};
	};

	// ------------------------- Canister Management -------------------------
	public query func version() : async Nat {
		return VERSION;
	};

	// ------------------------- Private Methods -------------------------
	private func clear_expired_chunks() : async () {
		let current_time = Time.now();
		let five_minutes = 5 * 60 * 1000000000; // Convert 5 minutes to nanoseconds

		let filtered_chunks = Map.mapFilter<Chunk_ID, FileChunk, FileChunk>(
			chunks,
			nhash,
			func(key : Chunk_ID, file_chunk : FileChunk) : ?FileChunk {
				let age = current_time - file_chunk.created;
				if (age <= five_minutes) {
					return ?file_chunk;
				} else {
					return null;
				};
			}
		);

		chunks := filtered_chunks;
	};

	// ------------------------- System Methods -------------------------
	system func preupgrade() {
		files_stable_storage := Iter.toArray(Map.entries(files));
		chunks_stable_storage := Iter.toArray(Map.entries(chunks));
	};

	system func postupgrade() {
		files := Map.fromIter<File_ID, File>(files_stable_storage.vals(), thash);

		ignore Timer.recurringTimer(#seconds(300), clear_expired_chunks);

		files_stable_storage := [];
	};
};
