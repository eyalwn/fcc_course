/* demonstration for a micro-service that uses SQL DB (PostgreSQL).
 * reviewed by Cursor agent.
 * exercise details:
 * https://www.freecodecamp.org/learn/back-end-development-and-apis/back-end-development-and-apis-projects/exercise-tracker
 */
const express = require('express')
const app = express()
const cors = require('cors')
require('dotenv').config()
const bodyParser = require('body-parser');
app.use(bodyParser.urlencoded({extended: false}));

/////////////// connect to postgre
const { Client } = require('pg');
let client;
async function startPostgreConnection() {
	const credentials = {
		user: process.env.DB_USER,
		host: process.env.DB_HOST,
		database: process.env.DB_NAME,
		password: process.env.DB_PASSWORD,
		port: process.env.DB_PORT,
	};
	// Using a Client for a single connection
	client = new Client(credentials);
	await client.connect();
}
await startPostgreConnection().catch(err => {
	console.error('[DB] Connection failed:', err);
	process.exit(1);
});

////////////////// routing
app.use(cors())
app.use(express.static('public'))
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/views/index.html')
});

app.get('/api/users', async (req, res) => {
	let result;
	try {
		result = await client.query('SELECT * FROM users;');
	} catch (error) {
		console.error("Database error:", error);
		return res.status(500).json({ error: "Database query failed", details: error.message });
	}
	const users = result.rows.map(row => ({
		_id: String(row.id),
		username: row.name
	}));
	res.json(users);
});

app.post('/api/users', async (req, res) => {
	const userName = req.body.username;
	let userId;
	try {
		userId = await client.query(
			`INSERT INTO users (name)
			VALUES ($1)
			RETURNING id;`,
			[userName]);
	} catch (error) {
		console.error("Database error:", error);
		return res.status(500).json({ error: "Database query failed", details: error.message });
	}
	userId = userId.rows[0].id;
	
	res.json({
		username: userName,
		_id: `${userId}`
	});
});

app.post('/api/users/:userId/exercises', async (req, res) => {
	const userId = req.params.userId;
	const description = req.body.description;
	const durationInMin = +req.body.duration; // client send parameter "duration", but its in minutes
	const rawDate = req.body.date;
	
	let date = rawDate ? new Date(rawDate) : new Date();
	if (isNaN(date.getTime())) {
		return res.status(400).json({ error: "Invalid date format" });
	}
	// Format the date as yyyy-mm-dd to store in database consistently
	const formattedDate = date.toISOString().slice(0, 10);
	
	// saving the exercise to the database and fetching username in a single query
	let username;
	try {
		const result = await client.query(
			`WITH inserted_exercise AS (
				INSERT INTO exercises (user_id, description, duration_in_min, date)
				VALUES ($1, $2, $3, $4)
				RETURNING user_id)
			SELECT u.name 
			FROM users u
			INNER JOIN inserted_exercise ie ON u.id = ie.user_id;`,
			[userId, description, durationInMin, formattedDate]);
		
		if (result.rows.length === 0) {
			return res.status(404).json({ error: "User not found" });
		}
		username = result.rows[0].name;
	} catch (error) {
		if (error.message && error.message.includes("violates foreign key constraint")) {
			return res.status(404).json({ error: "User not found" });
		}
		console.error("Database error:", error);
		return res.status(500).json({ error: "Database query failed", details: error.message });
	}
	// Format formattedDate as "Mon Jan 01 1990"
	const formattedDateStr = date.toDateString(); // Example: "Mon Jan 01 1990"
	
	res.json({
		"_id": userId,
		"username": username,
		"date": formattedDateStr,
		"duration": durationInMin,
		"description": description,
	});
});

app.get('/api/users/:_id/logs', async (req, res) => {
	const userId = req.params._id;
	const from = req.query.from;
	const to = req.query.to;
	const limit = req.query.limit;
	
	try {
		// Get username for the given userId
		const userResult = await client.query('SELECT name FROM users WHERE id = $1', [userId]);
		if (userResult.rows.length === 0) {
			return res.status(404).json({ error: "User not found" });
		}
		const username = userResult.rows[0].name;

		// Build filtering conditions for optional from/to dates
		let conditions = ['user_id = $1'];
		let values = [userId];
		let idx = 2;

		if (from) {
			conditions.push(`date >= $${idx}`);
			values.push(from);
			idx++;
		}
		if (to) {
			conditions.push(`date <= $${idx}`);
			values.push(to);
			idx++;
		}

		let queryStr = `SELECT description, duration_in_min, date FROM exercises WHERE ${conditions.join(' AND ')} ORDER BY date ASC`;
		if (limit) {
			queryStr += ` LIMIT $${idx}`;
			values.push(limit);
		}

		// Get exercises
		const exerciseResult = await client.query(queryStr, values);

		// Prepare log, formatting date
		const log = exerciseResult.rows.map(row => ({
			description: row.description,
			duration: Number(row.duration_in_min),
			date: new Date(row.date).toDateString()
		}));

		// Respond
		res.json({
			username,
			count: log.length,
			_id: userId,
			log
		});
	} catch (error) {
		console.error("Database error:", error);
		res.status(500).json({ error: "Database query failed", details: error.message });
	}
});


/////////////// start listen to socket
const listener = app.listen(process.env.PORT || 3000, () => {
  console.log('Server listening on http://localhost:' + listener.address().port)
})
