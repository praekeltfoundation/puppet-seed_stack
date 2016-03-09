#!/bin/bash

GROUP_JSON="${1?No group definition file given.}"
shift
MARATHON_HOST="${1-127.0.0.1}"
shift
MARATHON_PORT="${1-8080}"
shift

# curl will only return a non-zero exit code for an unsuccessful request if we
# pass --fail, and that suppresses output. Instead, we ask for all the response
# headers so we can look at the status code, and then strip out everything
# except the JSON response body.
resp=$(curl -Ssi -X PUT -d @"${GROUP_JSON}" \
            -H 'Content-Type: application/json' \
            -H 'Expect:' \
            "http://${MARATHON_HOST}:${MARATHON_PORT}/v2/groups")

echo "${resp}" | grep '^{'

if ! echo "${resp}" | head -n 1 | grep '200' > /dev/null; then
    echo "Application group update failed." >&2
    exit 1
fi
