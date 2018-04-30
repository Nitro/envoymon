module Envoymon
  class Collector
    @client : HTTP::Client?
    @last_fetch : Time
    @last_data : Hash(String, InsightsEvent)

    @headers : HTTP::Headers?

    getter   :last_data
    property :last_fetch

    def initialize(@hostname : String, @port : Int32)
      @last_data = Hash(String, InsightsEvent).new
      @last_fetch = Time.epoch(0)
    end

    def update
      response = fetch
      events = parse(response)
      result = calculate(events)

      @last_fetch = Time.utc_now
      @last_data = events

      result
    end

    def parse(response : HTTP::Client::Response?)
      data = Hash(String, Hash(String, Hash(String, Int64))).new
      return to_events(data) if response.nil?

      response.body.each_line(data) do |line|
        fields = line.split(/::/)

        next if fields.size < 4
        next if fields.last !~ /^[0-9.]+$/
        next if fields[1] !~ /:/

        data[fields[0]] = Hash(String, Hash(String, Int64)).new unless data.has_key?(fields[0])
        data[fields[0]][fields[1]] = Hash(String, Int64).new unless data[fields[0]].has_key?(fields[1])

        data[fields[0]][fields[1]][fields[2]] = fields[3].to_i64
      end

      to_events(data)
    end

    def calculate(data : Hash(String, InsightsEvent))
      return data if data.empty?

      # Skip out if we don't have anything to calculate against. We want
      # something in the last minute and ten seconds to allow a little
      # fudge factor around collection time.
      if @last_fetch < Time.utc_now - Time::Span.new(0, 1, 10)
        @last_fetch = Time.utc_now
        @last_data = data
        return Hash(String, InsightsEvent).new
      end

      # Find the difference between the last counts and current
      new_data = subtract(data, @last_data)
      @last_data = data

      new_data
    end

    def post_to_insights(events : Array(InsightsEvent))
      if events.empty?
        puts "Empty events, skipping post"
        return
      end

      body = generate_post_body(events)
      response = HTTP::Client.post(INSIGHTS_URL, headers, body)

      if response.status_code != 200
        puts "ERROR: Can't post to Insights: #{response.status_code} -> #{response.body}"
        return
      end

      puts "#{response.status_code} - #{response.body}"
    end

    def fetch
      response = nil
      begin
        response = client.get "/clusters"
        abort "Failed to fetch: #{response.status_message}" unless response.status_code == 200
      rescue e : Socket::Error | IO::Timeout
        abort "Can't connect: #{e}"
      end
      response
    end

    # ---------
    private def subtract(new_data, old_data)
      output = Hash(String, InsightsEvent).new
      new_data.each do |k, v|
        next unless old_data.has_key?(k)
        output[k] = old_data[k].subtract(v)
      end
      output
    end

    private def headers
      @headers ||= HTTP::Headers.new.tap do |h|
        h.add("Content-Type", "application/json")
        h.add("X-Insert-Key", INSIGHTS_INSERT_KEY)
      end
    end

    private def generate_post_body(events : Array(InsightsEvent))
      json_array = events.map do |evt|
        evt.to_json
      end
      "[" + json_array.join(",\n") + "]"
    end

    private def client
      @client ||= HTTP::Client.new(@hostname, @port).tap do |c|
        c.connect_timeout = 2
      end
    end

    private def to_events(data : Hash(String, Hash(String, Hash(String, Int64))))
      base_time = Time.utc_now
      data.reduce(Hash(String, InsightsEvent).new) do |memo, (name, values)|
        values.each do |v|
          memo[name] = InsightsEvent.new(base_time.to_s, name, values)
        end
        memo
      end
    end
  end
end
