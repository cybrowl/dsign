const response = process.argv[2];

function convertResponseToJson(response) {
	const cleaned = response
		.replace(/[\n\s]+/g, ' ')
		.replace(/vec \{ /, '')
		.replace(/\},/, '');
	const records = cleaned.split('record { ').filter((record) => record.length > 0);

	const jsonRecords = records.map((record) => {
		const properties = record
			.split(';')
			.filter((property) => property.length > 0 && property !== '}');
		const jsonObject = {};

		properties.forEach((property) => {
			const [key, value] = property.split(' = ');

			if (value) {
				const cleanedValue = value.replace(/_/, '').replace(/ : int/, '');

				if (key === 'created') {
					jsonObject[key] = parseInt(cleanedValue, 10);
				} else if (key === 'isProd') {
					jsonObject[key] = cleanedValue === 'true';
				} else {
					jsonObject[key] = cleanedValue;
				}
			}
		});

		return jsonObject;
	});

	return jsonRecords;
}

const jsonOutput = convertResponseToJson(response);

console.log(JSON.stringify(jsonOutput, null, 2));
