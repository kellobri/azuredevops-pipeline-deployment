#!/usr/bin/env bash
#
# Create a new content item in RStudio Connect or update an existing content item.
# Requires a unique content name (UNIQ_NAME) to perform a lookup of an existing content GUID.
#

#!/usr/bin/env bash
#
# Create a bundle, upload that bundle to RStudio Connect, deploy that bundle,
# then wait for deployment to complete.
#
# Run this script from the content root directory.
#

set -e

if [ -z "${CONNECT_SERVER}" ] ; then
    echo "The CONNECT_SERVER environment variable is not defined. It defines"
    echo "the base URL of your RStudio Connect instance."
    echo 
    echo "    export CONNECT_SERVER='http://connect.company.com/'"
    exit 1
fi

if [[ "${CONNECT_SERVER}" != */ ]] ; then
    echo "The CONNECT_SERVER environment variable must end in a trailing slash. It"
    echo "defines the base URL of your RStudio Connect instance."
    echo 
    echo "    export CONNECT_SERVER='http://connect.company.com/'"
    exit 1
fi

if [ -z "${CONNECT_API_KEY}" ] ; then
    echo "The CONNECT_API_KEY environment variable is not defined. It must contain"
    echo "an API key owned by a 'publisher' account in your RStudio Connect instance."
    echo
    echo "    export CONNECT_API_KEY='jIsDWwtuWWsRAwu0XoYpbyok2rlXfRWa'"
    exit 1
fi

OWNER_REQUEST=$(curl --silent --show-error -L --max-redirs 0 --fail -X GET \
    -H "Authorization: Key ${CONNECT_API_KEY}" \
    "${CONNECT_SERVER}__api__/v1/user")
OWNER_GUID=$(echo "$OWNER_REQUEST" | jq -r .guid)
echo "Owner GUID: ${OWNER_GUID}"

CONTENT_CHECK=$(curl --silent --show-error -L --max-redirs 0 --fail -X GET \
    -H "Authorization: Key ${CONNECT_API_KEY}" \
    "${CONNECT_SERVER}__api__/v1/content?name=${UNIQ_NAME}&owner_guid=${OWNER_GUID}")
echo "Existing content lookup result: ${CONTENT_CHECK}"
STR_CHECK=$(echo ${CONTENT_CHECK} | tr -d "[]")

BUNDLE_PATH="bundle.tar.gz"

# Remove any bundle from previous attempts.
rm -f "${BUNDLE_PATH}"

# Create an archive with all of our content source and data.
echo "Creating bundle archive: ${BUNDLE_PATH}"
tar czf "${BUNDLE_PATH}" -C "${CONTENT_DIRECTORY}" .

if [[ "${CONTENT_CHECK}" == *"guid"* ]] ; then
    echo "Updating an existing content item ..."
    echo "Content item info: ${STR_CHECK}"
    CONTENT=$(echo "${STR_CHECK}" | jq -r .guid)
else 
    echo "Creating a new content item ..."

    # Build the JSON to create content.
    DATA=$(jq --arg name  "${UNIQ_NAME}" \
    '. | .["name"]=$name' \
    <<<'{}')
    RESULT=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
                -H "Authorization: Key ${CONNECT_API_KEY}" \
                --data "${DATA}" \
                "${CONNECT_SERVER}__api__/v1/content")
    CONTENT=$(echo "$RESULT" | jq -r .guid)
    echo "Created content: ${CONTENT}"
fi

echo "##vso[task.setvariable variable=CONTENT]${CONTENT}"

# Upload the bundle
UPLOAD=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              --data-binary @"${BUNDLE_PATH}" \
              "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/bundles")
BUNDLE=$(echo "$UPLOAD" | jq -r .id)
echo "Created bundle: $BUNDLE"

# Deploy the bundle.
DATA=$(jq --arg bundle_id "${BUNDLE}" \
   '. | .["bundle_id"]=$bundle_id' \
   <<<'{}')
DEPLOY=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
              -c cookie.txt \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              --data "${DATA}" \
              "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/deploy")
TASK=$(echo "$DEPLOY" | jq -r .task_id)

# Poll until the task completes.
FINISHED=false
CODE=-1
FIRST=0
echo "Deployment task: ${TASK}"
while [ "${FINISHED}" != "true" ] ; do
    DATA=$(curl --silent --show-error -L --max-redirs 0 --fail \
              -b cookie.txt \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              "${CONNECT_SERVER}__api__/v1/tasks/${TASK}?wait=1&first=${FIRST}")
    # Extract parts of the task status.
    FINISHED=$(echo "${DATA}" | jq .finished)
    CODE=$(echo "${DATA}" | jq .code)
    FIRST=$(echo "${DATA}" | jq .last)
    # Present the latest output lines.
    echo "${DATA}" | jq  -r '.output | .[]'
done

if [ "${CODE}" -ne 0 ]; then
    ERROR=$(echo "${DATA}" | jq -r .error)
    echo "Task: ${TASK} ${ERROR}"
    exit 1
fi
echo "Task: ${TASK} Complete."