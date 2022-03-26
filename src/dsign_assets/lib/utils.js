export function getErrorMessage(response, errorMessages) {
	if (response.err) {
		let errorKey = Object.keys(response.err)[0];
		return errorMessages[errorKey];
	} else {
		return '';
	}
}
