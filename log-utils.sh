#!/bin/bash

declare -A levels=([VERBOSE]=0 [DEBUG]=1 [INFO]=2 [WARN]=3 [ERROR]=4)

# Default to VERBOSE if not defined the environment variable
if [[ ! -v script_logging_level ]] || [[ -z "$script_logging_level" ]]; then
  script_logging_level="VERBOSE"
fi

initLogs(){
    # If the logs folder does not exist, creates it
    if [ ! -d "$(pwd)/logs" ]; then
        mkdir "logs"
    fi

    NOW=`date '+%Y-%m-%d_%H_%M'`

    export LOG_FILE_NAME="$(pwd)/logs/script_${NOW}.log"
    
    echo "Saving logs to file: ${LOG_FILE_NAME}"
    echo ""
}

function logMessage() {
    local log_message=$1
    local log_priority=$2

    #echo "###"
    #echo "DEBUG: ${log_message}"
    #echo "DEBUG: ${log_priority}"
    #echo "###"

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 0

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$script_logging_level]} )) && return 0

    NOW=`date '+%Y-%m-%d %H:%M:%S'`

    #log here
    MESSAGE="${NOW} : ${log_priority} : ${log_message}"
    echo ${MESSAGE} | tee -a ${LOG_FILE_NAME} 
}
