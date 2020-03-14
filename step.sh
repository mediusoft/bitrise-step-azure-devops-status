#!/bin/bash
set -ex

echo "${devops_commit_state} ${devops_description}"

state=$devops_commit_state
description=$devops_description

if [ $state == "auto" ]
then
    state="failed"

    if [ $BITRISE_BUILD_STATUS -eq 0 ]
    then
        state="succeeded"
    fi
fi

if [ -z "$description" ]
then
    description="${BITRISE_APP_TITLE} build #${BITRISE_BUILD_NUMBER} ${state}"
fi

URL="https://${devops_user}:${devops_pat}@dev.azure.com/${devops_organization}/${devops_project}/_apis/git/repositories/${devops_repository_id}/commits/${BITRISE_GIT_COMMIT}/statuses?api-version=5.1"

HTTP_RESPONSE=$(curl $URL --silent --write-out "HTTPSTATUS:%{http_code}" \
-H "Content-Type: application/json" \
-d @- <<EOF
{
    "state": "${state}",
    "description": "${description}",
    "targetUrl": "${devops_target_url}",
    "context":  {
        "name": "${devops_context_name}",
        "genre": "${devops_context_genre}"
    }
}
EOF
)

HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')

if [ ! $HTTP_STATUS -eq 201  ]
then
  echo "Error [HTTP status: $HTTP_STATUS]"
  exit 1
fi