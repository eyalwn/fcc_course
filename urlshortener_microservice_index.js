require('dotenv').config();
const express = require('express');
const cors = require('cors');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: false}));
let urls = []; // list of original URLs; short_url matches array index

// Basic Configuration
const port = process.env.PORT || 3000;

app.use(cors());

app.use('/public', express.static(`${process.cwd()}/public`));

app.get('/', function(req, res) {
  res.sendFile(process.cwd() + '/views/index.html');
});

function isValidAddressFormat(address) {
	return address.startsWith('http://');
}

// Your first API endpoint
app.post('/api/shorturl', function(req, res) {
	if (req.body.url === undefined) {
		return res.json({error: 'missing body param: url'});
	}
	let original_url = req.body.url;
	if (!isValidAddressFormat(original_url)) {
		return res.json({ error: 'invalid url' });
	}
	
	let index = urls.indexOf(original_url);
	let short_url = 0;
	if (index !== -1) {
		short_url = index;
	} else {
		short_url = urls.length;
		urls.push(original_url);
	}
	res.json({ "original_url" : original_url, "short_url" : short_url});
});

app.get('/api/shorturl/:short_url', function(req, res) {
	let original_url;
	let shortUrl = +req.params.short_url;
	if (shortUrl >= 0 && shortUrl < urls.length) {
		original_url = urls[shortUrl];
		res.redirect(original_url);
	} else {
		res.json({ "error": 'No short URL found for the given input' });
	}
});

app.listen(port, function() {
  console.log(`Listening on port ${port}`);
});
