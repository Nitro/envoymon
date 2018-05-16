require "json"

module Envoymon
  class DiffError < Exception; end

  class InsightsEvent
    getter :data
    property :name
    getter :timestamp
    getter :environment

    def initialize(
      @timestamp : String,
      @name : String,
      @environment : String,
      @data : Hash(String, Hash(String, Int64))
    ); end

    def to_json
      return "{}" if @data.empty?

      service_port = @data.keys.first
      values = @data[service_port]

      JSON.build do |json|
        json.object do
          json.field "timestamp", @timestamp
          json.field "eventType", "EnvoyStats"
          json.field "environment", @environment
          json.field "service", @name
          json.field "sourceIpHost", service_port
          json.field "cx_active", values["cx_active"]
          json.field "cx_connect_fail", values["cx_connect_fail"]
          json.field "cx_total", values["cx_total"]
          json.field "rq_active", values["rq_active"]
          json.field "rq_error", values["rq_error"]
          json.field "rq_success", values["rq_success"]
          json.field "rq_timeout", values["rq_timeout"]
          json.field "rq_total", values["rq_total"]
          json.field "weight", values["weight"]
        end
      end
    end

    def subtract(other : InsightsEvent)
      raise DiffError.new("Event names don't match! ('#{other.name}' vs '#{@name}')") if other.name != @name

      # Preserve the fields that we don't subtract
      preserved_fields = %w{cx_active rq_active weight}
      result = Hash(String, Hash(String, Int64)).new

      preserved_fields.each do |stat_name|
        other.data.each do |host, values|
          next unless @data.has_key?(host)
          result[host] = Hash(String, Int64).new unless result.has_key?(host)
          result[host][stat_name] = values[stat_name]
        end
      end

      # All the other fields we'll just subtract the old from the current
      (other.data.first.last.keys - preserved_fields).each do |stat_name|
        other.data.each do |host, values|
          next unless @data.has_key?(host)
          result[host] = Hash(String, Int64).new unless result.has_key?(host)
          result[host][stat_name] = values[stat_name] - @data[host][stat_name]
          # If we rolled over the stat such that we'd end up with a
          # negative number, the implication is that the proxy restarted
          # during this minute and we can just use the new value.
          result[host][stat_name] = values[stat_name] if (result[host][stat_name] < 0_i64)
        end
      end

      InsightsEvent.new(other.timestamp, @name, @environment, result)
    end
  end
end
