#!/usr/bin/env crystal

# ------------------------------------------------------------------------------
# Envoymon
# ------------------------------------------------------------------------------
# Fetches data from an Envoy /clusters endpoint and relays stats to New Relic
# Insights via the Insights API. Keeps state between runs in memory and
# calculates differences in the results so that the counters are sent up as
# gauges instead.
# ------------------------------------------------------------------------------

require "http/client"
require "option_parser"
require "json"
require "logger"

require "./src/envoymon/insights_event"
require "./src/envoymon/insights_reporter"
require "./src/envoymon/collector"

port = 9901
hostname = "localhost"

INSIGHTS_URL        = "https://insights-collector.newrelic.com/v1/accounts/YOUR_ACCOUNT_NUMBER/events"
INSIGHTS_INSERT_KEY = "YOUR_INSIGHTS_KEY"

OptionParser.parse! do |parser|
  parser.banner = "Usage: envoymon [arguments]"
  parser.on("-h HOST", "--host=HOST", "The Envoy hostname")   { |h| hostname = h }
  parser.on("-p PORT", "--port=PORT", "The Enovy stats port") { |p| port = p.to_i }
  parser.on("--help", "Show this help") { puts parser; exit }
end

collector = Envoymon::Collector.new(hostname, port)
reporter = Envoymon::InsightsReporter.new(INSIGHTS_URL, INSIGHTS_INSERT_KEY)

def capture_timing(&block)
  start_time = Time.utc_now
  yield
  Time.utc_now - start_time
end

while true
  elapsed = capture_timing do
    events = collector.update
    if events.empty?
      Logger.new(STDOUT).info "Starting from empty state. Waiting for more data."
    else
      reporter.post_to_insights(events.values)
    end
  end

  # Sleep up to 1 minute, subtracting the elapsed run time to
  # try to keep on a 1 minute loop
  sleep(Time::Span.new(0, 1, 0) - elapsed)
end
