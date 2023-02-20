#!/bin/bash
set -e

REPOS_DIR=${1:-/etc/ostree/remotes.d}
URLS_WITH_PROBLEMS=()

get_update_platform_urls() {
    mapfile -t UPDATE_PLATFORM_URLS < <(grep -P -ho 'http[s]?.*' "${REPOS_DIR}"/*)
    if [[ ${#UPDATE_PLATFORM_URLS[@]} -eq 0 ]]; then
        echo "No update platforms found in ${REPOS_DIR}"
        exit 1
    fi
}

assert_update_platforms_are_responding() {
    readonly HTTP_OK=2
    readonly HTTP_REDIRECT=3

    for UPDATE_PLATFORM_URL in "${UPDATE_PLATFORM_URLS[@]}"; do
        HTTP_STATUS=$(curl -o /dev/null -Isw '%{http_code}\n' "$UPDATE_PLATFORM_URL" || echo "Unreachable")
        if ! [[ $HTTP_STATUS =~ ^($HTTP_OK|$HTTP_REDIRECT) ]]; then
            URLS_WITH_PROBLEMS+=( "$UPDATE_PLATFORM_URL" )
        fi
    done
    if [[ ${#URLS_WITH_PROBLEMS[@]} -eq 0 ]]; then
        echo "All update platforms are reachable"
    else
        echo "The following update platforms are unreachable:"
        printf "\t%s\n" "${URLS_WITH_PROBLEMS[@]}"
        exit 1
    fi
}

if [[ ! -d $REPOS_DIR ]]; then
    echo "${REPOS_DIR} does not exist"
    exit 1
fi

get_update_platform_urls
assert_update_platforms_are_responding
