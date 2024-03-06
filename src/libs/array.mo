import Buffer "mo:base/Buffer";

module {
	public func append<X>(array1 : [X], array2 : [X]) : [X] {
		let buff_combined = Buffer.Buffer<X>(array1.size() + array2.size());

		buff_combined.append(Buffer.fromArray(array1));
		buff_combined.append(Buffer.fromArray(array2));

		return Buffer.toArray(buff_combined);
	};
};
