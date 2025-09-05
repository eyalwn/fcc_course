#! /bin/bash

##################
# functions:
quit(){
	echo "I could not find that element in the database."
	exit
}
##################

PSQL="psql -U freecodecamp -d periodic_table -At -c"
USER_ARG=$1

if [ ! $# -gt 0 ]; then
	echo "Please provide an element as an argument."
	exit
fi

atomic_numbers=($($PSQL "SELECT atomic_number FROM elements;"))
elements_symbols=($($PSQL "SELECT symbol FROM elements;"))
elements_names=($($PSQL "SELECT name FROM elements;"))

if [[ $USER_ARG =~ ^[0-9]+$ ]]; then
	# input is an atomic number
	COL="atomic_number"
	relevant_arr=( "${atomic_numbers[@]}" )
elif [[ $USER_ARG =~ ^[[:alpha:]]+$ ]]; then
	# input is a word
	if [[ ${#USER_ARG} -lt 3 ]]; then
		# input is a symbol
		COL="symbol"
		relevant_arr=( "${elements_symbols[@]}" )
	else
		# input is an element name
		COL="name"
		relevant_arr=( "${elements_names[@]}" )
	fi
else
	quit
fi

# check if exist
if [[ ! " ${relevant_arr[@]} " =~ " ${USER_ARG} " ]]; then
	quit
fi

# get parameters for this element: name, symbol, type, mass, melting, boiling.
ATOMIC_SYMBOL_NAME=$($PSQL "
	SELECT atomic_number, symbol, name
	FROM elements
	WHERE $COL = '$USER_ARG';")
ATOMIC=$( echo $ATOMIC_SYMBOL_NAME | cut -d "|" -f 1)
SYMBOL=$( echo $ATOMIC_SYMBOL_NAME | cut -d "|" -f 2)
NAME=$( echo $ATOMIC_SYMBOL_NAME | cut -d "|" -f 3)

MASS_MELTING_BOILING_TYPEID=$($PSQL "
	SELECT atomic_mass, melting_point_celsius, boiling_point_celsius, type_id
	FROM properties
	WHERE atomic_number = $ATOMIC;")
MASS=$( echo $MASS_MELTING_BOILING_TYPEID | cut -d "|" -f 1)
MELTING=$( echo $MASS_MELTING_BOILING_TYPEID | cut -d "|" -f 2)
BOILING=$( echo $MASS_MELTING_BOILING_TYPEID | cut -d "|" -f 3)
TYPEID=$( echo $MASS_MELTING_BOILING_TYPEID | cut -d "|" -f 4)

TYPE=$($PSQL "
	SELECT type
	FROM types
	WHERE type_id = $TYPEID;")

echo "The element with atomic number $ATOMIC is $NAME ($SYMBOL). It's a $TYPE, with"\
	"a mass of $MASS amu. $NAME has a melting point of $MELTING celsius and a"\
	"boiling point of $BOILING celsius."
