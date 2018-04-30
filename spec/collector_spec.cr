require "spec2"
require "../src/envoymon/collector.cr"
require "webmock"

include Spec2::GlobalDSL

describe Envoymon::Collector do
  let(response1) { File.read("spec/fixtures/clusters_response.txt") }
  let(response2) { File.read("spec/fixtures/clusters_response_2.txt") }
  let(collector) { Envoymon::Collector.new("some-host", 666) }

  before do
    WebMock.stub(:get, "some-host:666/clusters").
      to_return(status: 200, body: response1)
  end

  after do
    WebMock.reset
  end

  describe "Fetching data" do
    it "fetches and parses data from Envoy" do
      collector.update

      expect(collector.last_data.keys.sort).to eq(
        %w{service-one-10012-public service-three-10120-public service-two-10123-public sidecar-sds}
      )
      expect(collector.last_data.first.last).to be_a(Envoymon::InsightsEvent)
    end
  end

  describe "Managing state" do
    it "subtracts previous data from the new data" do
      collector.update
      collector.last_fetch = Time.utc_now - Time::Span.new(-1, 1, 0)

      WebMock.reset
      WebMock.stub(:get, "some-host:666/clusters").
        to_return(status: 200, body: response2)

      original_data = collector.last_data
      result = collector.update

      expect(result["sidecar-sds"].data["127.0.0.1:7777"]["rq_total"]).to eq(220_i64)
      expect(result["sidecar-sds"].data["127.0.0.1:7777"]["rq_active"]).to eq(0_i64)
      expect(result["sidecar-sds"].data["127.0.0.1:7777"]["rq_success"]).to eq(220_i64)
    end

    it "updates the stored state with the latest data" do
      collector.update

      # Should have stored the latest events
      expect(collector.last_data["sidecar-sds"].data["127.0.0.1:7777"]["rq_total"]).to eq(537811_i64)

      # Timestamp should have been updated in the last two seconds (lots of slack here)
      expect(collector.last_fetch > Time.utc_now - Time::Span.new(0, 0, 2)).to be_true
    end
  end
end
