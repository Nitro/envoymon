require "spec2"
require "../src/envoymon/insights_event.cr"

include Spec2::GlobalDSL

describe Envoymon::InsightsEvent do
  let(base_time) { Time.utc_now - Time::Span.new(0, 1, 0) }
  let(base_event) do
    Envoymon::InsightsEvent.new(base_time.to_s, "nginx-raster-10111-public", "dev",
      {
        "10.4.18.35:24699" => {
          "cx_active"       => 4_i64,
          "cx_connect_fail" => 1_i64,
          "cx_total"        => 12541_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 0_i64,
          "rq_success"      => 53064_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53065_i64,
          "weight"          => 1_i64,
        },
        "10.4.18.235:31259" => {
          "cx_active"       => 4_i64,
          "cx_connect_fail" => 0_i64,
          "cx_total"        => 12449_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 1_i64,
          "rq_success"      => 53064_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53065_i64,
          "weight"          => 1_i64,
        },
        "10.4.19.228:30848" => {
          "cx_active"       => 5_i64,
          "cx_connect_fail" => 0_i64,
          "cx_total"        => 12521_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 1_i64,
          "rq_success"      => 53063_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53064_i64,
          "weight"          => 1_i64,
        },
      })
  end

  let(new_event) do
    Envoymon::InsightsEvent.new(base_time.to_s, "nginx-raster-10111-public", "dev",
      {
        "10.4.18.35:24699" => {
          "cx_active"       => 5_i64,
          "cx_connect_fail" => 1_i64,
          "cx_total"        => 12570_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 1_i64,
          "rq_success"      => 53184_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53185_i64,
          "weight"          => 1_i64,
        },
        "10.4.18.235:31259" => {
          "cx_active"       => 4_i64,
          "cx_connect_fail" => 0_i64,
          "cx_total"        => 12478_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 1_i64,
          "rq_success"      => 53183_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53184_i64,
          "weight"          => 1_i64,
        },
        "10.4.19.228:30848" => {
          "cx_active"       => 4_i64,
          "cx_connect_fail" => 0_i64,
          "cx_total"        => 12547_i64,
          "rq_active"       => 0_i64,
          "rq_error"        => 1_i64,
          "rq_success"      => 53183_i64,
          "rq_timeout"      => 0_i64,
          "rq_total"        => 53184_i64,
          "weight"          => 1_i64,
        },
      })
  end

  describe "When generating JSON" do
    it "doesn't crash when event is malformed" do
      evt = Envoymon::InsightsEvent.new(
        new_event.timestamp, # just re-use any valid timestamp
        "borked",
        "bork world",
        Hash(String, Hash(String, Int64)).new
      )

      expect { evt.to_json }.not_to raise_error
    end

    it "preserves the environment and service" do
      json = new_event.to_json

      expect(json).to match(/nginx-raster-10111-public/)
      expect(json).to match(/"environment":"dev"/)
    end
  end

  describe "Handling event subtraction" do
    it "raises when the event names don't match" do
      new_event.name = "Wrong!"
      expect { base_event.subtract(new_event) }.to raise_error(Envoymon::DiffError)
    end

    it "preserves the current values for some fields" do
      result = base_event.subtract(new_event)

      expect(result.data["10.4.18.35:24699"]["cx_active"]).to eq(5_i64)
      expect(result.data["10.4.18.35:24699"]["rq_active"]).to eq(0_i64)
      expect(result.data["10.4.18.35:24699"]["weight"]).to eq(1_i64)
    end

    it "subtracts the other fields" do
      result = base_event.subtract(new_event)

      expect(result.data["10.4.19.228:30848"]["rq_success"]).to eq(120_i64)
      expect(result.data["10.4.19.228:30848"]["cx_connect_fail"]).to eq(0_i64)
      expect(result.data["10.4.19.228:30848"]["rq_total"]).to eq(120_i64)
      expect(result.data["10.4.19.228:30848"]["cx_total"]).to eq(26_i64)
      expect(result.data["10.4.18.35:24699"]["rq_error"]).to eq(1_i64)
    end

    it "returns the new value rather than a negative" do
      new_event.data["10.4.19.228:30848"]["cx_total"] = 1_i64
      result = base_event.subtract(new_event)

      expect(result.data["10.4.19.228:30848"]["cx_total"]).to eq(1_i64)
    end

    it "builds the right events in subtract()" do
      result = base_event.subtract(new_event)

      expect(result.timestamp).to match(/^[0-9]{4}-[0-9]{2}-[0-9]{2}/)
      expect(result.name).to eq("nginx-raster-10111-public")
    end

    it "does not pass through new entries that don't exist in the old set" do
      new_event.data["10.4.19.123:12312"] = new_event.data["10.4.19.228:30848"]
      result = base_event.subtract(new_event)

      expect(result.data.keys.includes?("10.4.19.123:12312")).to be_false
      expect(result.data.keys.includes?("10.4.19.228:30848")).to be_true
    end
  end
end
