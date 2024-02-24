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

	public func random_from_time() : [Nat] {
		var randomness = Buffer<Nat>(0);

		let hash : Nat32 = hashNat(Int.abs(Time.now()));

		let seed = Nat32.toNat(hash);

		for (i in Iter.range(0, 32)) {
			if (i == 0) {
				randomness.add(seed);
			} else {
				let prev = randomness.get(i - 1);
				let hash_prev : Nat32 = hashNat(prev);

				let next = Nat32.toNat(hash_prev);
				randomness.add(next);
			};
		};

		return toArray(randomness);
	};

	public func generate_uuid() : Text {
		let hex_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
		var uuid = Buffer<Char>(0);

		let randomness = random_from_time();

		for (i in Iter.range(0, 32)) {
			if (i == 8 or i == 12 or i == 16 or i == 20) {
				uuid.add('-');
			} else {
				uuid.add(hex_chars[randomness[i] % 16]);
			};
		};

		let uuid_arr = toArray(uuid);

		return Text.fromIter(uuid_arr.vals());
	};
};
