import Char "mo:base/Char";
import Text "mo:base/Text";

module {
	public func username_valid(username : Text) : Bool {
		if (username.size() > 20) {
			return false;
		};

		if (username.size() < 2) {
			return false;
		};

		var isValidUsername = true;

		// check if char is lowercase letter or number
		for (char in username.chars()) {
			let isAZ = Char.isAlphabetic(char);
			let isDigit = Char.isDigit(char);
			let isLowercase = Char.isLowercase(char);

			if (isAZ == false) {
				if (isDigit == false) {
					isValidUsername := false;
				};
			};

			if (isAZ == true) {
				if (isLowercase == false) {
					isValidUsername := false;
				};
			};
		};

		return isValidUsername;
	};
};
