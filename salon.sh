#! /bin/bash

PSQL="psql -U freecodecamp -d salon -At -c"

# get service IDs & names
service_ids=($($PSQL "SELECT service_id FROM services;"))
service_names=($($PSQL "SELECT name FROM services;"))
# validate service indices
for i in "${!service_ids[@]}"; do
	service_id=${service_ids[$i]}
	service_name=${service_names[$i]}
	if [[ $((i+1)) != $service_id ]]; then
		echo "ERROR: i+1 ($((i+1))) != service_id ($service_id)"
		exit -1
	fi
done

echo "~~~~~ MY SALON ~~~~~

Welcome to My Salon, how can I help you?
"
while [[ -z $USER_CHOICE_IS_VALID ]]
do
	# display options
	for i in "${!service_ids[@]}"; do
		echo "${service_ids[$i]}) ${service_names[$i]}"
	done
	# get user input
	read SERVICE_ID_SELECTED
	echo ""
	# validate user choice:
	# translation: "if service_ids[] contains SERVICE_ID_SELECTED; then"
	if [[ " ${service_ids[@]} " =~ " ${SERVICE_ID_SELECTED} " ]]; then
		USER_CHOICE_IS_VALID=1
	else
		echo "I could not find that service. What would you like today?"
	fi
done
REQUESTED_SERVICE=${service_names[(($SERVICE_ID_SELECTED-1))]}

phone_numbers=($($PSQL "SELECT phone FROM customers;"))
echo "What's your phone number?"
read CUSTOMER_PHONE
echo ""

# translation: "if phone_numbers[] does not contain CUSTOMER_PHONE; then"
if [[ ! " ${phone_numbers[@]} " =~ " ${CUSTOMER_PHONE} " ]]; then
	echo "I don't have a record for that phone number, what's your name?"
	read CUSTOMER_NAME
	echo ""
	$PSQL "INSERT INTO customers VALUES (default, '$CUSTOMER_NAME', '$CUSTOMER_PHONE');" > /dev/null
	echo "you have been added to the black list"
	echo "(______)"
	echo "| \  / |"
	echo "| '  ' |"
	echo "| \__/ |"
	echo " \____/"
	echo ""
else
	CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE';")
fi
USER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")

echo "What time would you like your $REQUESTED_SERVICE, $CUSTOMER_NAME?"
read SERVICE_TIME
echo ""
$PSQL "INSERT INTO appointments VALUES (
	default, '$SERVICE_TIME', '$USER_ID', '$SERVICE_ID_SELECTED');" > /dev/null

# SUBTASKS 1.1 :21 You should display the suggested message after adding an new appointment
echo "I have put you down for a $REQUESTED_SERVICE at $SERVICE_TIME, $CUSTOMER_NAME."
