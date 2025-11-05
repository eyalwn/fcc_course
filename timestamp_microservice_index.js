// index.js
// where your node app starts

// init project
var express = require('express');
const path = require('path')
var app = express();

// enable CORS (https://en.wikipedia.org/wiki/Cross-origin_resource_sharing)
// so that your API is remotely testable by FCC 
var cors = require('cors');
app.use(cors({optionsSuccessStatus: 200}));  // some legacy browsers choke on 204

// http://expressjs.com/en/starter/static-files.html
app.use(express.static('public'));

// http://expressjs.com/en/starter/basic-routing.html
app.get("/", function (req, res) {
  res.sendFile(__dirname + '/views/index.html');
});


// your first API endpoint... 
app.get("/api/:timestamp?", (req, res) => {
	console.log(`req.params.timestamp ${req.params.timestamp}`);
	let retObj = {};
	
	if (req.params.timestamp === undefined) {
		let now = new Date();
		retObj = {
			"unix": now.getTime(),
			"utc":now.toUTCString()
		};
	}
	else {
		// now timestamp is certainely a string
		let timestamp;
		if (!isNaN(+req.params.timestamp)) {
			// timestamp is a number
			timestamp = +req.params.timestamp;
		}
		else {
			// string with other format (probably a date format)
			timestamp = req.params.timestamp;
		}
		timestamp = new Date(timestamp);
		
		if (timestamp.toString() !== "Invalid Date") {
			retObj = {
				"unix": timestamp.getTime(),
				"utc":timestamp.toUTCString()
			};
		} else {
			// smth in the format is wrong
			retObj = { error : "Invalid Date" };
		}
	}
	
	res.json(retObj);
	console.log(retObj);
});



// Listen on port set in environment variable or default to 3000
var listener = app.listen(process.env.PORT || 3000, function () {
  console.log('Your app is listening on port ' + listener.address().port);
});
