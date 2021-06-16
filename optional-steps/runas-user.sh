#!/usr/bin/env bash
#
# Set the RunAs User for a piece of Content 
# given the Content GUID, UNIX user name, and a valid API key
# - Applies only to executable content types 
# - Only administrators can change this value
#

# Build the JSON to create a runas user update request
DATA=$(jq --arg run_as "${RUNAS_USER}" \
   '. | .["run_as"]=$run_as ' \
   <<<'{}')
   
echo "Trying to update RunAs User: ${CONNECT_SERVER}__api__/v1/content/${CONTENT}"

echo "${DATA}"

RESULT=$(curl --silent --show-error -L --max-redirs 0 --fail -X PATCH \
    -H "Authorization: Key ${CONNECT_API_KEY}" \
    --data-binary "${DATA}" \
    "${CONNECT_SERVER}__api__/v1/content/${CONTENT}")
RESPONSE=$(echo "$RESULT" | jq -r .path)

echo "RunAs User: ${RESPONSE} Update Complete."