Envoymon
========

Fetches data from an Envoy `/clusters` endpoint and relays stats to New Relic
Insights via the Insights API. Keeps state between runs in memory and
calculates differences in the results so that the counters are sent up as
gauges instead.

Sample New Relic Insights dashboard using data from Envoymon:
![Sample Dashboard](assets/envoy_dash.png)

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
