# Hostping monitoring

Send Telegram alert when the specified host does not respond to ICMP echo requests(id. est. ping)

<https://gitlab.com/brlin/hostping-monitoring>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/hostping-monitoring/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/hostping-monitoring/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/hostping-monitoring/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/hostping-monitoring/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/hostping-monitoring "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/hostping-monitoring)

## Prerequisites

This application requires the following dependencies to be installed and available in your command search PATHs:

* [Bash](https://www.gnu.org/software/bash/)  
  For running the monitoring program itself.  Requires Bash >=4.2.
* [Coreutils - GNU core utilities](https://www.gnu.org/software/coreutils/)(or feature-wise equivalent counterparts)  
  For the following functionalities including but not limited to:
    + For determining the monitoring program's full path.
    + For letting the monitoring process to sleep during the montioring interval.
* [telegram-send](https://github.com/rahiel/telegram-send?tab=readme-ov-file)  
  For sending Telegram messages to your specified user/group/channel chat.  You'll also need to have your Telegram bot registered, its authentication token acquired, and [have the telegram-send utility configured to be able to send messages to your specified destination.](https://github.com/rahiel/telegram-send#installation)

## Terminology

The following is the terms specifically used in this solution:

### Check

The operation that checks whether a certain host is alive.

### Action

The operation that the monitoring solution took when a certain host is considered DOWN or UP.

## Environment variables that will change the monitoring program's behaviors

The following section documents the environment variables that will change the monitoring program's runtime behavoirs:

### MONITOR_INTERVAL

The seconds between each host monitoring check action.

**Default value:** `10`

### CHECK_HOST

The host to check ping response from.

**Default value:** `localhost`

### CHECK_PING_TIMEOUT

How long to wait for the ICMP response before considering the ping check has failed.  The unit is in seconds(fractions are allowed).

**Default value:** `1.0`

### MONITOR_HOST_UP_THRESHOLD

Consequential successful check quantity to consider the host is up.

**Default value:** `2`

### MONITOR_HOST_DOWN_THRESHOLD

Consequential failure check quantity to consider the host is down.

**Default value:** `2`

## Verification

For Linux operating system distributions that uses either:

* The iptables packet filtering system
* iptables-nft atop of the nftables packet filtering system

Run the following command to drop the outgoing response packets of ICMP echo requests:

```bash
iptables_opts_drop_response=(
    # Append rule to the OUTPUT chain
    -A OUTPUT

    # Select loopback as the outgoing network interface
    -o lo

    # Drop ICMP echo response packets
    -p icmp --icmp-type echo-reply -j DROP
)
if ! sudo iptables-nft "${iptables_opts_drop_response[@]}"; then
    printf \
        'Error: Unable to filter the outgoing response packets of ICMP echo requests.\n' \
        1>&2
fi
```

You may now emulate the monitoring events by running the following command in the product directory:

```bash
MONITOR_INTERVAL=1 ./monitor-host-ping.sh
```

To revert the change to the firewall, run the following command (in a different text terminal window or terminal multiplexer pane:

```bash
iptables_opts_remove_rule=(
    # Delete rule of the OUTPUT chain that matches the following rule
    # specification
    -D OUTPUT

    # Select loopback as the outgoing network interface
    -o lo

    # Drop ICMP echo response packets
    -p icmp --icmp-type echo-reply -j DROP
)
if ! sudo iptables-nft "${iptables_opts_remove_rule[@]}"; then
    printf \
        'Error: Unable to remove the filtering of the outgoing response packets of ICMP echo requests.\n' \
        1>&2
fi
```

## References

In the development of this product, the following material is referenced:

* ping(1) manual page  
  Explains the `-W` command-line option and the command's exit status codes.
* [Arithmetic Evaluation Explained | OpenAI ChatGPT](https://chat.openai.com/share/5f5baedd-6414-4971-99cc-910dbea49b7a)  
  Explains the menaing of the "arithmetic evaluation ( Shell Arithmetic) is performed when the variable is assigned a value." part of the `-i` command-line option description of the `declare` bash builtin command.

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the version 3 of the GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
