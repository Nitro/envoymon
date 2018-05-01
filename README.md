Envoymon
========

Fetches data from an Envoy /clusters endpoint and relays stats to New Relic
Insights via the Insights API. Keeps state between runs in memory and
calculates differences in the results so that the counters are sent up as
gauges instead.

Building
--------

On a Linux host with Docker, run `./build.sh`. The binary will be dropped
into the current directory.