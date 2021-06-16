#!/usr/bin/env bash
#
# Set the vanity URL for a piece of Content forcefully 
# given the Content GUID and a valid API key
#

# Build the JSON to create a vanity force update request
DATA=$(jq --arg path "${VANITY_NAME}" \
   --argjson force true \
   '. | .["path"]=$path | .["force"]=$force' \
   <<<'{}')
   
echo "Trying: ${CONNECT_SERVER}__api__/v1/content/${CONTENT}/vanity"

echo "${DATA}"

RESULT=$(curl --silent --show-error -L --max-redirs 0 --fail -X PUT \
    -H "Authorization: Key ${CONNECT_API_KEY}" \
    --data-binary "${DATA}" \
    "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/vanity")
RESPONSE=$(echo "$RESULT" | jq -r .path)

echo "Vanity URL: ${RESPONSE} Update Complete."