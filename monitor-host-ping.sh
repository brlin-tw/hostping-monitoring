#!/usr/bin/env bash
# Monitor host ping response and send Telegram alert message when
# the host doesn't respond
#
# Copyright 2024 林博仁(Buo-ren, Lin) <buo.ren.lin@gmail.com>
# SPDX-License-Identifier: AGPL-3.0-or-later

init(){
    local environment_file="${script_dir}/.env"
    if ! test -e "${environment_file}"; then
        printf \
            'Error: The environment file(.env) does not exist in the product directory.\n' \
            1>&2
        exit 1
    fi

    printf \
        'Info: Loading the environment file...\n'
    # shellcheck source=.env
    if ! source "${environment_file}"; then
        printf \
            'Error: Unable to load the environment file.\n' \
            1>&2
        exit 2
    fi

    if ! check_runtime_parameters \
        MONITOR_INTERVAL \
        CHECK_PING_TIMEOUT \
        MONITOR_HOST_UP_THRESHOLD \
        MONITOR_HOST_DOWN_THRESHOLD; then
        printf \
            'Error: Runtime parameter check failed.\n' \
            1>&2
        exit 1
    fi

    local host_state=UP
    printf \
        'Info: Assuming the default host state is %s.\n' \
        "${host_state}"

    local -i \
        consequential_successful_check_count=0 \
        consequential_failure_check_count=0
    local -a ping_opts=(
        # Only ping once
        -c 1

        # Set timeout for waiting the response packet
        -W "${CHECK_PING_TIMEOUT}"

        # Don't display individual ping record
        -q
    )
    local -i overflow_prevention_counter_upper_limit=9999
    while true; do
        if ! ping "${ping_opts[@]}" "${CHECK_HOST}" >/dev/null; then
            printf \
                'Warning: The ping attempt to the host "%s" has failed.\n' \
                "${CHECK_HOST}" \
                1>&2
            # NOTE: When a arithmetic expression is evaluated to zero,
            # the '((' compound command has a non-zero exit status ,
            # which we do not like it to trigger errexit
            ((consequential_successful_check_count = 0)) || true

            # Avoid overflowing the counter
            if test "${consequential_failure_check_count}" -eq "${overflow_prevention_counter_upper_limit}"; then
                : # Don't increment the counter
            else
                ((consequential_failure_check_count += 1))
            fi
        else
            ((consequential_failure_check_count = 0)) || true
            # Avoid overflowing the counter
            if test "${consequential_failure_check_count}" -eq "${overflow_prevention_counter_upper_limit}"; then
                : # Don't increment the counter
            else
                ((consequential_successful_check_count += 1))
            fi
        fi

        if test "${host_state}" == UP \
            && test "${consequential_failure_check_count}" -ge "${MONITOR_HOST_DOWN_THRESHOLD}"; then
            host_state=DOWN
            printf \
                'Warning: The host DOWN threshold has exceeded, sending alert notification...\n' \
                1>&2
        fi

        if test "${host_state}" == DOWN \
            && test "${consequential_successful_check_count}" -ge "${MONITOR_HOST_UP_THRESHOLD}"; then
            host_state=UP
            printf \
                'Info: The host UP threshold has exceeded, sending alert notification...\n'
        fi

        printf \
            'Debug: host_state=%s consequential_successful_check_count=%s consequential_failure_check_count=%s.\n' \
            "${host_state}" \
            "${consequential_successful_check_count}" \
            "${consequential_failure_check_count}" \
            1>&2

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
        local -n monitor_interval_ref="${1}"; shift
        local -n check_ping_timeout_ref="${1}"; shift
        local -n monitor_host_up_threshold_ref="${1}"; shift
        local -n monitor_host_down_threshold_ref="${1}"; shift
    }

    printf \
        'Info: Checking the runtime parameters...\n'
    local regex_non_negative_integers='^(0|[1-9][[:digit:]]*)$'
    local regex_non_negative_fraction_numbers='^(0|[1-9][[:digit:]]*)(\.[[:digit:]]+)?$'

    printf \
        'Info: Checking whether all the runtime parameters are set...\n'
    local runtime_parameter_assignment_check_failed=false
    local -a all_runtime_parameters=(
        monitor_interval_ref
        check_ping_timeout_ref
        monitor_host_up_threshold_ref
        monitor_host_down_threshold_ref
    )
    for parameter in "${all_runtime_parameters[@]}"; do
        if ! test -v "${parameter}"; then
            runtime_parameter_assignment_check_failed=true

            parameter_name="${parameter%_ref}"

            printf \
                'Error: The %s runtime parameter is not set.\n' \
                "${parameter_name^^*}" \
                1>&2
        fi
    done
    if test "${runtime_parameter_assignment_check_failed}" == true; then
        printf \
            'Error: Runtime parameter assignment check failed.\n' \
            1>&2
        return 1
    fi

    printf \
        'Info: Validating the values of the non-negative integer parameters...\n'
    local -a non_negative_integer_parameters=(
        monitor_interval_ref
        monitor_host_up_threshold_ref
        monitor_host_down_threshold_ref
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

    printf \
        'Info: Validating the values of the non-negative fraction parameters...\n'
    local -a non_negative_fraction_parameters=(
        check_ping_timeout_ref
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
