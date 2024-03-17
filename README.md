# Hostping monitoring

Send Telegram alert when the specified host does not respond to ICMP echo requests(id. est. ping)

<https://gitlab.com/brlin/hostping-monitoring>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/brlin/hostping-monitoring/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/brlin/hostping-monitoring/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/brlin-tw/hostping-monitoring/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/brlin-tw/hostping-monitoring/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/brlin/hostping-monitoring "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/brlin/hostping-monitoring)

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

**Default value:** `60`

### CHECK_HOST

The host to check ping response from.

**Default value:** `localhost`

### CHECK_PING_TIMEOUT

How long to wait for the ICMP response before considering the ping check has failed.  The unit is in seconds(fractions are allowed).

**Default value:** `1`

## References

In the development of this product, the following material is referenced:

* ping(1) manual page  
  Explains the `-W` command-line option and the command's exit status codes.

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the version 3 of the GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
