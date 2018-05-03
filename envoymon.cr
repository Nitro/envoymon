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
insights_url = ""
insights_key = ""
environment = "dev" # e.g. dev|prod|test

OptionParser.parse! do |parser|
  parser.banner = "Usage: envoymon [arguments]"
  parser.on("-h HOST", "--host=HOST", "The Envoy hostname") { |h| hostname = h }
  parser.on("-p PORT", "--port=PORT", "The Enovy stats port") { |p| port = p.to_i }
  parser.on("-i URL", "--insights-url=URL", "Insights URL to report to") { |u| insights_url = u }
  parser.on("-k KEY", "--insights-key=KEY", "Insights Insert key") { |k| insights_key = k }
  parser.on("-e ENV", "--environment=ENV", "Runtime environment name") { |e| environment = e }
  parser.on("--help", "Show this help") { puts parser; exit }
end

if insights_key.empty? || insights_url.empty?
  abort "Insights URL and Key are required. Try --help"
end

collector = Envoymon::Collector.new(hostname, port, environment)
reporter = Envoymon::InsightsReporter.new(insights_url, insights_key)

def capture_timing(&block)
  start_time = Time.utc_now
  yield
  Time.utc_now - start_time
end

# Try to keep on a nearly 1 minute schedule by sleeping a little
# less than 1 minute when possible
def maybe_sleep(elapsed)
  maybe_sleep_time = Time::Span.new(0, 1, 0) - elapsed
  sleep(maybe_sleep_time) if maybe_sleep_time > Time::Span.new(0, 0, 0)
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

  maybe_sleep(elapsed)
end
