#!/usr/bin/env bash
# Monitor host ping response and send Telegram alert message when
# the host doesn't respond
#
# Copyright 2024 林博仁(Buo-ren, Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

init(){
    while true; do
        printf \
            'Info: Sleep for %s seconds until the next check iteration...\n' \
            "${CHECK_INTERVAL}"
        if ! sleep "${CHECK_INTERVAL}"; then
            printf \
                'Error: Unable to sleep for "%s" seconds.\n' \
                "${CHECK_INTERVAL}"
            exit 2
        fi
    done
}

printf \
    'Info: Configuring the defensive interpreter behavior...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to set the defensive interpreter behavior.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Checking the existence of the base required commands...\n'
required_commands=(
    realpath
)
flag_dependency_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        flag_dependency_check_failed=true
        printf \
            'Error: Unable to locate the "%s" command in the command search PATHs.\n' \
            "${command}" \
            1>&2
    fi
done
if test "${flag_dependency_check_failed}" == true; then
    printf \
        'Error: Dependency check failed, please check your installation.\n' \
        1>&2
    exit 1
fi

printf \
    'Info: Configuring the convenience variables...\n'
if test -v BASH_SOURCE; then
    # Convenience variables
    # shellcheck disable=SC2034
    {
        if ! script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
            )"; then
            printf \
                'Error: Unable to query the absolute path of the program.\n' \
                1>&2
            exit 1
        fi
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
        script_opts=("${@}")
    }
fi

init
