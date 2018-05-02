Insights NRQL Queries
=====================

Here are some example queries for building dashboards on New Relic Insights
using this application. The idea here is just to get you started. You can
easily change the queries to match your own needs.

Throughput by Service
---------------------

```
SELECT rate(sum(rq_total), 1 minute)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES
```

Errors by Service
-----------------

```
SELECT sum(rq_error)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES
```

Endpoint Count by Service
-------------------------

```
SELECT uniquecount(sourceIpHost)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES 1 minute
```

Connections per Service
-----------------------
```
SELECT rate(sum(cx_total), 1 minute)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES
```

Active Requests by Service
--------------------------

```
SELECT rate(sum(rq_active), 1 minute)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES
```

Active Connections by Service
-----------------------------

```
SELECT rate(sum(cx_active), 1 minute)
	FROM EnvoyStats
	WHERE environment = 'prod'
	FACET service
	TIMESERIES
```
