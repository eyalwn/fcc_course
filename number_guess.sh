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
	$PSQL "INSERT INTO users VALUES (DEFAULT, '$USER_NAME');" > /dev/null
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USER_NAME';")
	$PSQL "INSERT INTO users_info VALUES ($USER_ID, DEFAULT, DEFAULT);" > /dev/null
	echo "Welcome, $USER_NAME! It looks like this is your first time here."
	# for later
	GAMES_COUNT=$($PSQL "SELECT games_count FROM users_info WHERE user_id = $USER_ID;")
	BEST_SCORE=$($PSQL "SELECT best_score FROM users_info WHERE user_id = $USER_ID;")
else
	GAMES_COUNT=$($PSQL "SELECT games_count FROM users_info WHERE user_id = $USER_ID;")
	BEST_SCORE=$($PSQL "SELECT best_score FROM users_info WHERE user_id = $USER_ID;")
	echo "Welcome back, $USER_NAME! You have played $GAMES_COUNT games,"\
		"and your best game took $BEST_SCORE guesses."
fi

MAX=1000
MIN=1
SECRET_NUMBER=$(( $RANDOM % ($MAX - $MIN + 1) + $MIN ))
TRIES_COUNT=0

while [ 1 ]; do
	echo "Guess the secret number between 1 and 1000:"
	read USER_GUESS
	
	if !(is_integer "$USER_GUESS"); then
		echo "That is not an integer, guess again:"
		continue
	else
		((TRIES_COUNT++))
		if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
			echo "It's higher than that, guess again:"
		elif [[ $USER_GUESS -gt $SECRET_NUMBER ]]; then
			echo "It's lower than that, guess again:"
		elif [[ $USER_GUESS -eq $SECRET_NUMBER ]]; then
			echo "You guessed it in $TRIES_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
			break
		fi
	fi
done

((GAMES_COUNT++))
$PSQL "UPDATE users_info SET games_count = $GAMES_COUNT WHERE user_id = $USER_ID;" > /dev/null
if [[ $TRIES_COUNT -lt $BEST_SCORE ]]; then
	BEST_SCORE=$TRIES_COUNT
	$PSQL "UPDATE users_info SET best_score = $BEST_SCORE WHERE user_id = $USER_ID;" > /dev/null
fi
