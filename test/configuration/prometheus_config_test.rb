require "test_helper"

class PrometheusConfigTest < ActiveSupport::TestCase
  test "scrapes the Docker Rails and Sidekiq exporters" do
    config = YAML.safe_load_file(Rails.root.join("config/prometheus/prometheus.local.yml"))
    rails_job = config.fetch("scrape_configs").find { |job| job.fetch("job_name") == "rails" }
    sidekiq_job = config.fetch("scrape_configs").find { |job| job.fetch("job_name") == "sidekiq" }

    assert_equal [ "web:80" ], rails_job.dig("static_configs", 0, "targets")
    assert_equal [ "worker:9394" ], sidekiq_job.dig("static_configs", 0, "targets")
  end
end
