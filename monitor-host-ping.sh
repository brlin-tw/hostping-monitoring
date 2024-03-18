#!/usr/bin/env bash
# Monitor host ping response and send Telegram alert message when
# the host doesn't respond
#
# Copyright 2024 林博仁(Buo-ren, Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
CHECK_HOST="${CHECK_HOST:-localhost}"
CHECK_PING_TIMEOUT="${CHECK_PING_TIMEOUT:-1.0}"

MONITOR_INTERVAL="${MONITOR_INTERVAL:-10}"

init(){
    if ! check_runtime_parameters \
        "${MONITOR_INTERVAL}" \
        "${CHECK_PING_TIMEOUT}"; then
        printf \
            'Error: Runtime parameter check failed.\n' \
            1>&2
        exit 1
    fi

    local -a ping_opts=(
        # Only ping once
        -c 1

        # Set timeout for waiting the response packet
        -W "${CHECK_PING_TIMEOUT}"

        # Don't display individual ping record
        -q
    )
    while true; do
        if ! ping "${ping_opts[@]}" "${CHECK_HOST}" >/dev/null; then
            printf \
                'Warning: The ping attempt to the host "%s" has failed.\n' \
                "${CHECK_HOST}" \
                1>&2
        fi

        printf \
            'Info: Sleep for %s seconds until the next check iteration...\n' \
            "${MONITOR_INTERVAL}"
        if ! sleep "${MONITOR_INTERVAL}"; then
            printf \
                'Error: Unable to sleep until the next check iteration.\n' \
                1>&2
            exit 2
        fi
    done
}

# Check whether the value of the runtime parameters are valid
check_runtime_parameters(){
    # These variables are referenced indirectly
    # shellcheck disable=SC2034
    {
        local monitor_interval="${1}"; shift
        local check_ping_timeout="${1}"; shift
    }

    local regex_non_negative_integers='^(0|[1-9][[:digit:]]*)$'
    local regex_non_negative_fraction_numbers='^(0|[1-9][[:digit:]]*)(\.[[:digit:]]+)?$'

    local -a non_negative_integer_parameters=(
        monitor_interval
    )
    for parameter in "${non_negative_integer_parameters[@]}"; do
        printf \
            "Info: Validating the %s parameter's value...\\n" \
            "${parameter^^*}"
        if ! [[ "${!parameter}" =~ ${regex_non_negative_integers} ]]; then
            printf \
                "Error: The %s parameter's value should be an non-negative integer.\\n" \
                "${parameter^^*}" \
                1>&2
            return 2
        fi
    done

    local -a non_negative_fraction_parameters=(
        check_ping_timeout
    )
    for parameter in "${non_negative_fraction_parameters[@]}"; do
        printf \
            "Info: Validating the %s parameter's value...\\n" \
            "${parameter^^*}"
        if ! [[ "${!parameter}" =~ ${regex_non_negative_fraction_numbers} ]]; then
            printf \
                "Error: The %s parameter's value should be an non-negative fractional number or integer.\\n" \
                "${parameter^^*}" \
                1>&2
            return 2
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
