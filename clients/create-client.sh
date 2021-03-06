#!/bin/bash

set -eo pipefail
declare -r DIR=$(dirname ${BASH_SOURCE[0]})

which awk > /dev/null || { echo >&2 "error: awk not found"; exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-a access_token] [-n name] [-t type] [-v|-h]
        -e file         # .env file location (default cwd)
        -a token        # access_token. default from environment variable
        -n name         # client name (e.g. "My Client")
        -t type         # client type: spa, regular_web, native, non_interactive
        -h|?            # usage
        -v              # verbose

eg,
     $0 -n "My App" -t non_interactive
END
    exit $1
}

declare client_name=''
declare client_type=''

while getopts "e:a:n:t:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        a) access_token=${OPTARG};;
        n) client_name=${OPTARG};;
        t) client_type=(${OPTARG});;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
[[ -z "${client_name}" ]] && { echo >&2 "ERROR: client_name undefined."; usage 1; }
[[ -z "${client_type}" ]] && { echo >&2 "ERROR: client_type undefined."; usage 1; }

declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

for s in `echo $api_scopes | tr ',' ' '`; do
    scopes+="{\"value\":\"${s}\"},"
done
scopes=${scopes%?}

declare BODY=$(cat <<EOL
{
  "name": "${client_name}",
  "app_type": "${client_type}",
  "is_first_party": true
}
EOL
)

curl -k --request POST \
    -H "Authorization: Bearer ${access_token}" \
    --data "${BODY}" \
    --header 'content-type: application/json' \
    --url ${AUTH0_DOMAIN_URL}api/v2/clients 

