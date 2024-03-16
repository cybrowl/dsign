import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {
	public func append<X>(array1 : [X], array2 : [X]) : [X] {
		let buff_combined = Buffer.Buffer<X>(array1.size() + array2.size());

		buff_combined.append(Buffer.fromArray(array1));
		buff_combined.append(Buffer.fromArray(array2));

		return Buffer.toArray(buff_combined);
	};

	public func exists<X>(array : [X], predicate : X -> Bool) : Bool {
		let result = Array.find<X>(array, predicate);

		switch (result) {
			case (null) {
				false;
			};
			case (_) {
				true;
			};
		};
	};

	public func replace<X>(array : [X], index : Nat, new_element : X) : [X] {
		var result : [var X] = Array.thaw(array);

		result[index] := new_element;

		return Array.freeze(result);
	};

	public func findIndex<X>(array : [X], predicate : X -> Bool) : ?Nat {
		for (index in Array.keys(array)) {
			if (predicate(array[index])) {
				return ?index;
			};
		};

		return null;
	};
};
