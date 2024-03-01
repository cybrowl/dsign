import { Buffer; toArray } "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Map "mo:map/Map";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Time "mo:base/Time";

module {
	let { hashNat } = Map;
	// Hexadecimal characters for converting numbers to hex.
	let HEX_CHARS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
	let UUID_LENGTH = 31;

	// Generates a sequence of natural numbers based on time-derived randomness.
	public func random_from_time() : [Nat] {
		var randomness = Buffer<Nat>(0);
		// Seed based on the current time, hashed for initial randomness.
		let seed = Nat32.toNat(hashNat(Int.abs(Time.now())));

		// Initialize the randomness buffer with the seed.
		randomness.add(seed);
		// Generate subsequent numbers based on hashing the previous value.
		for (i in Iter.range(1, UUID_LENGTH)) {
			// Adjusted range to generate 32 elements in total.
			let prev = randomness.get(i - 1);
			randomness.add(Nat32.toNat(hashNat(prev)));
		};

		return toArray(randomness);
	};

	// Generates a UUID-like string without hyphens.
	public func generate() : Text {
		var uuid = Buffer<Char>(0);
		// Generate randomness based on the current time.
		let randomness = random_from_time();

		// Convert each piece of randomness into a hexadecimal character.
		for (i in Iter.range(0, UUID_LENGTH)) {
			// Adjusted range to match the number of generated elements.
			uuid.add(HEX_CHARS[randomness[i] % 16]);
		};

		// Convert the buffer to an array and then to a string.
		return Text.fromIter(toArray(uuid).vals());
	};
};
