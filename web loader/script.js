function load() {
	const margin = Number(document.getElementById("margin").value);
	const maxWidth = 400 - margin * 2;
	const file = document.getElementById("file").files[0];
	const name = file.name + ".json";
	file.text().then((text) => {
		text = text.replace(/\t/g, "    ");
		let lines = text.split(/\r?\n/);
		let index = 0;
		while (index < lines.length) {
			const line = lines[index];
			let width = 0;
			let space = 0;
			for (let c = 0; c < line.length; c++) {
				if (line[c] in widths) {
					width += widths[line[c]] + tracking;
				} else {
					width += missingWidth + tracking;
				}
				if (c > 0 && line.substring(c - 1, c + 1) in kerning) {
					width += kerning[line.substring(c - 1, c + 1)];
				}
				if (width - tracking > maxWidth) {
					if (space > 0) {
						lines[index] = line.substring(0, space);
						lines.splice(index + 1, 0, line.substring(space + 1));
					} else {
						lines[index] = line.substring(0, c);
						lines.splice(index + 1, 0, line.substring(c));
					}
					break;
				}
				if (line[c] === " ") {
					space = c;
				}
			}
			index++;
		}
		const output = JSON.stringify(lines);
		let a = document.createElement("a");
		a.href = URL.createObjectURL(new File([output], name));
		a.download = name;
		a.click();
	});
}

const missingWidth = 18;
const tracking = 1;
const widths = {};
const kerning = {};
