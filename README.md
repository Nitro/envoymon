Envoymon
========

[![](https://images.microbadger.com/badges/image/gonitro/envoymon.svg)](https://microbadger.com/images/gonitro/envoymon "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/gonitro/envoymon.svg)](https://microbadger.com/images/gonitro/envoymon "Get your own version badge on microbadger.com")

Fetches data from an Envoy `/clusters` endpoint and relays stats to New Relic
Insights via the Insights API. Keeps state between runs in memory and
calculates differences in the results so that the counters are sent up as
gauges instead.

Sample New Relic Insights dashboard using data from Envoymon:
![Sample Dashboard](assets/envoy_dash.png)

Configuration
-------------

If you run envoymon on the CLI, you can use command line optinos to configure
it. Example help output:

```
$ ./envoymon --help
Usage: envoymon [arguments]
    -h HOST, --host=HOST             The Envoy hostname
    -p PORT, --port=PORT             The Enovy stats port
    -i URL, --insights-url=URL       Insights URL to report to
    -k KEY, --insights-key=KEY       Insights Insert key
    -e ENV, --environment=ENV        Runtime environment name
    --help                           Show this help
```

If you are running the Docker container, you may configure it with the
following environment variables:

 * `ENVOYMON_HOST`: The Envoy hostname
 * `ENVOYMON_PORT`: The Enovy stats port
 * `ENVOYMON_INSIGHTS_URL`: New Relic Insights URL to report to
 * `ENVOYMON_INSIGHTS_INSERT_KEY`: New Relic Insights Insights Insert key
 * `ENVOYMON_ENVIRONMENT`: A name for this environment, usually something
    like 'production', 'prod', 'development', or 'staging'.

Building
--------

On a Linux host with Docker, run `./build.sh`. A container based on Alpine
Linux is the result. It will be pushed to Docker Hub automatically, tagged
with the most recent git sha.

Contributing
------------

Contributions are more than welcome. Bug reports with specific reproduction
steps are great. If you have a code contribution you'd like to make, open a
pull request with suggested code.

Pull requests should:

 * Clearly state their intent in the title
 * Have a description that explains the need for the changes
 * Include tests!
 * Not break the public API

If you are simply looking to contribute to the project, taking on one of the
items in the "Future Additions" section above would be a great place to start.
Ping us to let us know you're working on it by opening a GitHub Issue on the
project.

Copyright (c) 2018 Nitro Software
