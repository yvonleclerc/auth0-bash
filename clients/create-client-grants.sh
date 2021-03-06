#!/bin/bash

set -eo pipefail
declare -r DIR=$(dirname ${BASH_SOURCE[0]})

which awk > /dev/null || { echo >&2 "error: awk not found"; exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-A access_token] [-i client_id] [-a audience] [-s scopes] [-m|-v|-h]
        -e file         # .env file location (default cwd)
        -A token        # access_token. default from environment variable
        -i id           # client id
        -a audience     # resource server API audience
        -s scopes       # scopes to grant
        -m              # Management API audience
        -h|?            # usage
        -v              # verbose

eg,
     $0 -i Q1p8BJPS4yu24GjYaG1YQxxfoAhF4Gbe -m -s read:client_grants,create:client_grants
END
    exit $1
}

declare client_id=''
declare audience=''
declare api_scopes=''
declare use_management_api=0

while getopts "e:A:i:a:s:mhv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        A) access_token=${OPTARG};;
        i) client_id=${OPTARG};;
        a) audience=${OPTARG};;
        s) api_scopes=${OPTARG};;
        m) use_management_api=1;;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')
[[ ! -z "${use_management_api}" ]] && audience=${AUTH0_DOMAIN_URL}api/v2/
[[ -z "${client_id}" ]] && { echo >&2 "ERROR: client_id undefined."; usage 1; }


for s in `echo $api_scopes | tr ',' ' '`; do
    scopes+="\"${s}\","
done
scopes=${scopes%?}

declare BODY=$(cat <<EOL
{
  "client_id": "${client_id}",
  "audience": "${audience}",
  "scope": [ ${scopes} ]
}
EOL
)

curl -k --request POST \
    -H "Authorization: Bearer ${access_token}" \
    --data "${BODY}" \
    --header 'content-type: application/json' \
    --url ${AUTH0_DOMAIN_URL}api/v2/client-grants

