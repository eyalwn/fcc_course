#!/bin/bash

##################
# functions:
is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}
##################

PSQL="psql -U freecodecamp -d number_guess -At -c"

echo "Enter your username:"
read USER_NAME
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")
if [[ -z $USER_ID ]]; then
	$PSQL "INSERT INTO users(name) VALUES ('$USER_NAME');" > /dev/null
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")
	echo "Welcome, $USER_NAME! It looks like this is your first time here."
else
	GAMES_COUNT=$($PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID;")
	BEST_SCORE=$($PSQL "SELECT MIN(n_guesses) FROM games WHERE user_id = $USER_ID;")
	echo "Welcome back, $USER_NAME! You have played $GAMES_COUNT games,"\
		"and your best game took $BEST_SCORE guesses."
fi
$PSQL "INSERT INTO games(user_id) VALUES ('$USER_ID');" > /dev/null
GAME_ID=$($PSQL "SELECT MAX(game_id) FROM games WHERE user_id = '$USER_ID';")

MAX=1000
MIN=1
SECRET_NUMBER=$(( $RANDOM % ($MAX - $MIN + 1) + $MIN ))
TRIES_COUNT=0

echo "Guess the secret number between 1 and 1000:"
while [ 1 ]; do
	read USER_GUESS
	
	if !(is_integer "$USER_GUESS"); then
		echo -e "That is not an integer, guess again:\n"
		continue
	else
		((TRIES_COUNT++))
		if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
			echo -e "It's higher than that, guess again:\n"
		elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]; then
			echo -e "It's lower than that, guess again:\n"
		elif [[ $USER_GUESS -eq $SECRET_NUMBER ]]; then
			echo "You guessed it in $TRIES_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
			break
		fi
	fi
done

$PSQL "UPDATE games SET n_guesses = $TRIES_COUNT WHERE game_id = $GAME_ID;" > /dev/null
