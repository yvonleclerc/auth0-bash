#!/bin/bash

set -eo pipefail
declare -r DIR=$(dirname ${BASH_SOURCE[0]})

which awk > /dev/null || { echo >&2 "error: awk not found"; exit 3; }

function usage() {
    cat <<END >&2
USAGE: $0 [-e env] [-a access_token] [-i id] [-v|-h]
        -e file         # .env file location (default cwd)
        -a token        # access_token. default from environment variable
        -i id           # client id
        -h|?            # usage
        -v              # verbose

eg,
     $0 -i 
END
    exit $1
}

declare client_id=''

while getopts "e:a:i:n:s:hv?" opt
do
    case ${opt} in
        e) source ${OPTARG};;
        a) access_token=${OPTARG};;
        i) client_id=${OPTARG};;
        v) opt_verbose=1;; #set -x;;
        h|?) usage 0;;
        *) usage 1;;
    esac
done

[[ -z "${access_token}" ]] && { echo >&2 "ERROR: access_token undefined. export access_token='PASTE' "; usage 1; }
[[ -z "${client_id}" ]] && { echo >&2 "ERROR: client_id undefined."; usage 1; }

declare -r AUTH0_DOMAIN_URL=$(echo ${access_token} | awk -F. '{print $2}' | base64 -di 2>/dev/null | jq -r '.iss')

curl --request DELETE \
    -H "Authorization: Bearer ${access_token}" \
    --url ${AUTH0_DOMAIN_URL}api/v2/clients/${client_id} 

