const express = require('express')
const path = require('path')

const app = express()
const port = process.env.PORT || 3000

// Serve static assets
app.use('/public', express.static(path.join(__dirname, 'public')))

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'views', 'index.html'))
})

app.get("/api/:timestamp", (req, res) => {
	let timestamp = new Date(req.params.timestamp);
	
	if (timestamp.toString() === "Invalid Date") {
		let timestampAsNum = +req.params.timestamp;
		if (isNaN(timestampAsNum)) {
			res.end();
			console.error(`Error: timestampAsNum = ${timestampAsNum}`);
		}
		timestamp = new Date(timestampAsNum);
	}
	
	let obj = {
		"unix": timestamp.getTime(),
		"utc":timestamp.toUTCString()
	};
	res.json(obj);
});

app.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`)
})
