require "test_helper"

class PrometheusConfigTest < ActiveSupport::TestCase
  test "scrapes the local Sidekiq exporter" do
    config = YAML.safe_load_file(Rails.root.join("config/prometheus/prometheus.local.yml"))
    sidekiq_job = config.fetch("scrape_configs").find { |job| job.fetch("job_name") == "sidekiq" }

    assert_equal [ "localhost:9394" ], sidekiq_job.dig("static_configs", 0, "targets")
  end
end
