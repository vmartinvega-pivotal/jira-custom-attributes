´
# Add/Update Enhanced Project Properties plugin

The script allows to add or modify attributes in jira projects. In order to use this script the plugin [Enhanced Project Properties](https://marketplace.atlassian.com/apps/1217709/enhanced-project-properties?hosting=server&tab=overview) needs to be installed in Jira.   

## Input parameters
| Parameter      | Description | Default Value | Required? |
| -------------- | ----------- | ------------- | --------- |
| **--url**    | Jira url | https://jira.almpre.europe.cloudcenter.corp | Yes |
| **--input**    | Location for the input file with the information to be uploaded to Jira | input_file (in the folder where the script is executed) | Yes |
| **--attribute**    | Attribute name to be added/updated | entity | Yes |

At execution time the script will ask for the username/password to be used to connect to jira. The provided user MUST have permissions to access all projects configured in the input_file.

Execution example
```
./script.sh -i ./input_file -u https://jira.almpre.europe.cloudcenter.corp -a entity
```

## Script logic
Lets assume that *JIRA_URL* refers to the configured value at execution time (parameter --url), *ATTRIBUTE* refers to the configured value at execution time (parameter --attribute), *PROJECT_KEY* refers to the value read from the input file line and ATTRIBUTE_VALUE refers to the value read from the input file.

The script will read line by line the input file. 
For every line the script will access the following jira api url: 
**JIRA_URL/rest/projectproperties/1.0/property/list/PROJECT_KEY/key/ATTRIBUTE** (GET), to check if the attribute is already present at jira. 

IF PRESENT 

the script will update the value accessing the following url:**JIRA_URL/rest/projectproperties/1.0/property/update** (POST) where the body for the request is: 
"{"projectKey":"$PROJECT_KEY","propertyKey":"ATTRIBUTE","propertyValue":"ATTRIBUTE_VALUE"}"

IF NOT PRESENT

the script will add the attribute with its value accessing the following url:**JIRA_URL/rest/projectproperties/1.0/property/add** (POST) where the body for the request is: 
"{"projectKey":"$PROJECT_KEY","propertyKey":"ATTRIBUTE","propertyValue":"ATTRIBUTE_VALUE"}"

## Input file format
The input file will be created in the following way.
* The file is composed by lines which are interpreted separately, that is, every line will end up in a call to the jira API to modify/add the attribute.
* Every line is composed by two fields separated by pipes. The first field refers to the **project key** in jira and the second one refers to the value to be set up for the attribute that was configured at execution time (parameter --attribute), that is, **attribute value**

Input file line example
```
SDT | entity1
```

## Log configuration
The script can be configured with the following levels for logging: VERBOSE, DEBUG, INFO, WARN and ERROR.

The logging level can be configured with the environment variable **script_logging_level**. The default value is INFO.

The logs are written to the console and to a file in the **logs** folder. The created file is named as: **script_yyyy-MM-dd_hh_mm.log**

Example. To execute the script with a log level of ERROR
```
export script_logging_level=ERROR && ./script.sh -i input_file
```

