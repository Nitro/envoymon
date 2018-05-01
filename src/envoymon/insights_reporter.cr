require "logger"

module Envoymon
  class InsightsReporter

    @headers : HTTP::Headers
    @logger : Logger?

    def initialize(@insights_url : String, @insights_key : String)
      @headers = HTTP::Headers.new.tap do |h|
        h.add("Content-Type", "application/json")
        h.add("X-Insert-Key", @insights_key)
      end
    end

    def post_to_insights(events : Array(InsightsEvent))
      if events.empty?
        log.info "Empty events, skipping post"
        return
      end

      body = generate_post_body(events)
      response = HTTP::Client.post(@insights_url, @headers, body)

      if response.status_code != 200
        log.error "ERROR: Can't post to Insights: #{response.status_code} -> #{response.body}"
        return
      end

      log.info "Insights upload success: #{response.status_code} - #{response.body}"
    end

    private def generate_post_body(events : Array(InsightsEvent))
      json_array = events.map do |evt|
        evt.to_json
      end
      "[" + json_array.join(",\n") + "]"
    end

    private def log
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end
  end
end
