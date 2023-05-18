export function replacer(key, value) {
	if (typeof value === 'bigint') {
		return value.toString(); // convert BigInt to string
	} else {
		return value;
	}
}

export function reviver(key, value) {
	if (/^\d+$/.test(value)) {
		return BigInt(value); // convert string to BigInt
	} else {
		return value; // return as is
	}
}
