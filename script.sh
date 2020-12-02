#!/bin/bash

# Default value for the attribute to change
ATTRIBUTE="entity" # Default value
JIRA_URL="https://jira.almpre.europe.cloudcenter.corp" # Default value
INPUT_FILE=""
UPDATE="false"

while [ "$1" != "" ]; do
    case $1 in
        -u | --url )            shift
                                JIRA_URL=$1
                                ;;
        -i | --input )          INPUT_FILE=$2
                                ;;
        -a | --attribute )      ATTRIBUTE=$2
                                ;;
        -o | --overwrite )      UPDATE=$2
                                ;;
        -h | --help )           echo 'Please provide the jira url -u, attribute to change -a (default $ATTRIBUTE), input file -i and -o if update the value (default false)'
                                exit
                                ;;
        * )
    esac
    shift
done

function toLowerCase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

if [[ "${INPUT_FILE:-}" == "" ]]; then
  echo "The input file is required! Provide a value for it with (-i | --input). Exiting..."
  exit 1
fi

UPDATE=$(toLowerCase $UPDATE)
echo "Script parameters"
echo ""
echo "attribute to change: $ATTRIBUTE"
echo "jira url: $JIRA_URL"
echo "input file: $INPUT_FILE"
echo "update value: $UPDATE" 
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

echo "Please provide the credentials to access ${JIRA_URL}..."
echo
read -r -p "Username: " USERNAME
read -r -s -p "Password: " PASSWORD
echo

while IFS= read -r line
do
  # Gets the project key
  PROJECT_KEY=$(cut -d'|' -f1 <<< $line)

  # Gets the attribute entity value
  ATTRIBUTE_VALUE=$(cut -d'|' -f2 <<< $line)

  logMessage "Cheking if the attribute '$ATTRIBUTE' exists in the project: '$PROJECT_KEY'" "INFO"
  
  url="$JIRA_URL/rest/projectproperties/1.0/property/list/$PROJECT_KEY/key/$ATTRIBUTE"
  logMessage "Accessing url: $url" "DEBUG"

  # Check if the attribute exists
  response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" $url)
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

      url="$JIRA_URL/rest/projectproperties/1.0/property/add"
      logMessage "Accessing url: $url, with message: $message" "DEBUG"
      response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" --header "Content-Type: application/json" --request POST --data "$message" $url)
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
      if [[ $UPDATE = "true" ]]
      then
        logMessage "Updating the attribute '$ATTRIBUTE' in the project: '$PROJECT_KEY' with a value of '$ATTRIBUTE_VALUE'" "INFO"
        message="{\"projectKey\":\"$PROJECT_KEY\",\"propertyKey\":\"$ATTRIBUTE\",\"propertyValue\":\"$ATTRIBUTE_VALUE\"}"

        url="$JIRA_URL/rest/projectproperties/1.0/property/update"
        logMessage "Accessing url: $url, with message: $message" "DEBUG"

        response=$(curl --user $USERNAME:$PASSWORD --insecure -s -w "\n%{http_code}" --header "Content-Type: application/json" --request POST --data "$message" $url)
        response=(${response[@]}) # convert to array
        code=${response[-1]} # get last element (last line)
        body=${response[@]::${#response[@]}-1} # get all elements except last
        if [[ $code = "200" ]]
        then
          logMessage "Updated successfully the attribute '$ATTRIBUTE'!" "INFO"
        else
          logMessage "Error updating the attribute. Http code: $code" "ERROR"
        fi
      else
        logMessage "The script is configured to no overwrite the value. Check with the owner for the project key: '$PROJECT_KEY' if they were using the attribute name: '$ATTRIBUTE' previously." "WARN"
      fi
    fi
  else
    logMessage "Error accessing the url. Http code result: $code" "ERROR"
  fi

  # If not exists craete
    
done < "$INPUT_FILE"
