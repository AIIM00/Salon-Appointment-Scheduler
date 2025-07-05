#Initialize
#! /bin/bash
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

# Display services Menu
MAIN_MENU() {
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done
}

# Prompt for Valid Service
MAIN_MENU
while true
do
  read SERVICE_ID_SELECTED

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  if [[ -z $SERVICE_NAME ]]
  then
    echo -e "\nI could not find that service. What would you like today?\n"
    MAIN_MENU
  else
    break
  fi
done

# Get phone number
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")

# If not found, get name and insert new customer
if [[ -z $CUSTOMER_NAME ]]
then 
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  INSERT_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
fi
#Handle Customer Info
# Get time
echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME
#Schedule Appointment (Check Conflict)
if [[ -n $SERVICE_TIME ]]
then
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  TIME_TAKEN=$($PSQL "SELECT appointment_id FROM appointments WHERE time = '$SERVICE_TIME' AND service_id = $SERVICE_ID_SELECTED;")

  if [[ -z $TIME_TAKEN ]]
  then
    # Insert appointment
    INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")
    echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  #Show Available Times If Slot Is Taken
  else
    echo -e "\nSorry $CUSTOMER_NAME, $SERVICE_TIME is already taken. Would you like to see available times? (Y/N)"
    read OPTION

    if [[ $OPTION == "Y" || $OPTION == "y" ]]
    then
      ALL_TIMES=("09:00" "10:00" "11:00" "12:00" "13:00" "14:00" "15:00" "16:00" "17:00" "18:00")
      BOOKED_TIMES=$($PSQL "SELECT DISTINCT time FROM appointments WHERE service_id = $SERVICE_ID_SELECTED ORDER BY time;")

      BOOKED=()
      while IFS= read -r T; do
        BOOKED+=("$T")
      done <<< "$BOOKED_TIMES"

      echo -e "\nHere are some available times for $SERVICE_NAME:\n"
      for TIME_SLOT in "${ALL_TIMES[@]}"
      do 
        FOUND=false
        for B in "${BOOKED[@]}"
        do
          if [[ "$B" == "$TIME_SLOT" ]]
          then
            FOUND=true
            break
          fi
        done
        if [[ $FOUND == false ]]
        then
          echo "$TIME_SLOT"
        fi
      done
    fi
  fi
fi