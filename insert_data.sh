#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
set -e
echo $($PSQL "TRUNCATE teams, games;")
echo $($PSQL "ALTER SEQUENCE games_game_id_seq RESTART;")
echo $($PSQL "ALTER SEQUENCE teams_team_id_seq RESTART;")

# function to avoid code duplication
get_team_id_and_add_if_not_exist() {
	# input: TEAM_NAME (string)
	# output: via the variable TEAM_ID
	TEAM_NAME="$1"
	TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$TEAM_NAME';")
	if [[ -z $TEAM_ID ]]; then
		echo "inserting team '$TEAM_NAME'"
		INSERT_CMD_OUTPUT=$($PSQL "INSERT INTO teams VALUES (DEFAULT, '$TEAM_NAME');")
		TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$TEAM_NAME';")
	fi
}

tail -n +2 "games.csv" | while IFS=',' read -r \
	YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS;
do
	# echo "$YEAR, $ROUND, $WINNER, $OPPONENT, $WINNER_GOALS, $OPPONENT_GOALS"
	get_team_id_and_add_if_not_exist "$WINNER"
	WINNER_ID=$TEAM_ID
	get_team_id_and_add_if_not_exist "$OPPONENT"
	OPPONENT_ID=$TEAM_ID
	
	INSERT_CMD_OUTPUT=$($PSQL "INSERT INTO \
		games(game_id, year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES \
		(DEFAULT, $YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS);")
done

echo "DONE"
