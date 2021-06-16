#!/usr/bin/env bash
#
# Update the ACL settings for a piece of content on RSC
# given the Content GUID, User/Group GUID, and a valid API key
# Example shows how to add Viewer access for a given Group.
#

# Build the JSON request data for adding a Viewer Group to the content ACL
DATA=$(jq --arg principal_guid "${GROUP_GUID}" \
   '. | .["principal_guid"]=$principal_guid' \
   <<<'{"principal_type":"group","role":"viewer"}')

echo "${DATA}"

RESULT=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
    -H "Authorization: Key ${CONNECT_API_KEY}" \
    --data-binary "${DATA}" \
    "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/permissions")
RESPONSE=$(echo "$RESULT" | jq -r .id)

echo "ACL permissions: ${RESPONSE} Update Complete."