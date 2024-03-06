import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Random "mo:base/Random";
import Text "mo:base/Text";

module {
	func digit_to_hext(digit : Nat) : Text {
		let hexChars : [Text] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];

		return hexChars[digit];
	};

	public func generate_random_hex(len : Nat) : async Text {
		let entropy_blob = await Random.blob();
		let random = Random.Finite(entropy_blob);

		let hex_buffer = Buffer.Buffer<Text>(0);

		for (_ in Iter.range(0, Int.sub(len, 1))) {
			switch (random.byte()) {
				case (?b) {
					let high = Nat8.toNat(b) / 16;
					let low = Nat8.toNat(b) % 16;

					// Add hex characters to the buffer
					hex_buffer.add(digit_to_hext(high));
					hex_buffer.add(digit_to_hext(low));
				};
				case null {};
			};
		};

		let hex_array = Buffer.toArray(hex_buffer);

		return Text.join("", hex_array.vals());
	};

	public func generate() : async Text {
		let random_hex = await generate_random_hex(12);

		return random_hex;
	};
};
