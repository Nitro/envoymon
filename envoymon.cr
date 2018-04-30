#!/usr/bin/env crystal

require "http/client"
require "option_parser"
require "json"

require "./src/envoymon/insights_event"
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

def capture_timing(&block)
  start_time = Time.utc_now
  yield
  Time.utc_now - start_time
end

while true
  elapsed = capture_timing do
    response = collector.update
    if response.empty?
      puts "empty"
    else
      p response["sidecar-sds"].data["127.0.0.1:7777"]["rq_total"]
    end
  end

  # Sleep up to 1 minute, subtracting the elapsed run time to
  # try to keep on a 1 minute loop
  sleep(Time::Span.new(0, 0, 10) - elapsed)
end
