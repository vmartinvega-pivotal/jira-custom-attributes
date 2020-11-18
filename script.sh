#!/bin/bash

# Default value for the attribute to change
ATTRIBUTE="entity"

while [ "$1" != "" ]; do
    case $1 in
        -t | --token )          shift
                                JIRA_TOKEN=$1
                                ;;
        -i | --input )          INPUT_FILE=$2
                                ;;
        -a | --input )          ATTRIBUTE=$2
                                ;;
        -h | --help )           echo 'Please provide the jira token -t, attribute to change -a (default $ATTRIBUTE) and input file -i'
                                exit
                                ;;
        * )
    esac
    shift
done

function toLowerCase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

echo "Script parameters"
echo ""
echo "attribute to change: $ATTRIBUTE"
echo "jira token: $JIRA_TOKEN"
echo "input file: $INPUT_FILE"
echo ""

# If log level is not set it is initialized as INFO
if [[ ! -v script_logging_level ]] || [[ -z "$script_logging_level" ]]; then
  export script_logging_level="INFO"
fi

# Source utils
echo "Sourcing files..."
echo ""
source log-utils.sh

# Init log file
initLogs

USERNAME=""
PASSWORD=""

while IFS= read -r line
do
  PROJECT_KEY=$(cut -d'|' -f1 <<< $line)
  ATTRIBUTE_VALUE=$(cut -d'|' -f2 <<< $line)

  logMessage "Cheking if the attribute '$ATTRIBUTE' exists in the project: '$PROJECT_KEY'" "INFO"
  
  # Check if the attribute exists
  response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" https://jira.almpre.europe.cloudcenter.corp/rest/projectproperties/1.0/property/list/$PROJECT_KEY/key/$ATTRIBUTE)
  response=(${response[@]}) # convert to array
  code=${response[-1]} # get last element (last line)
  body=${response[@]::${#response[@]}-1} # get all elements except last


  # Cheks the http_code
  if [[ $code = "200" ]]
  then
    logMessage "Http code result: $code" "DEBUG"
    logMessage "Returned body: $body" "DEBUG"
    # Checks if the attribute exists
    if [[ $body = "" ]]
    then
      logMessage "Adding the attribute '$ATTRIBUTE' in the project: '$PROJECT_KEY' with a value of '$ATTRIBUTE_VALUE'" "INFO"
      message="{\"projectKey\":\"$PROJECT_KEY\",\"propertyKey\":\"$ATTRIBUTE\",\"propertyValue\":\"$ATTRIBUTE_VALUE\"}"

      response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" --header "Content-Type: application/json" --request POST --data "$message" https://jira.almpre.europe.cloudcenter.corp/rest/projectproperties/1.0/property/add)
      response=(${response[@]}) # convert to array
      code=${response[-1]} # get last element (last line)
      body=${response[@]::${#response[@]}-1} # get all elements except last
      if [[ $code = "200" ]]
      then
        logMessage "Added successfully the attribute!" "INFO"
      else
        logMessage "Error adding the attribute. Http code: $code" "ERROR"
      fi
    else
      logMessage "Updating the attribute '$ATTRIBUTE' in the project: '$PROJECT_KEY' with a value of '$ATTRIBUTE_VALUE'" "INFO"

      response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" -XDELETE https://jira.almpre.europe.cloudcenter.corp/rest/projectproperties/1.0/property/remove/$PROJECT_KEY/$ATTRIBUTE)
      response=(${response[@]}) # convert to array
      code=${response[-1]} # get last element (last line)
      body=${response[@]::${#response[@]}-1} # get all elements except last
      if [[ $code = "200" ]]
      then
         logMessage "Removed successfully the attribute '$ATTRIBUTE' from the project: '$PROJECT_KEY'" "INFO"
      else
         logMessage "Error removing the attribute '$ATTRIBUTE' in the project: '$PROJECT_KEY'. Http code: $code" "ERROR"
      fi
    fi
  else
    logMessage "Error accessing the url. Http code result: $code" "ERROR"
  fi

  # If not exists craete
    
done < "$INPUT_FILE"
