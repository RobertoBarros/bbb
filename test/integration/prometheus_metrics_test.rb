require "test_helper"

class PrometheusMetricsTest < ActionDispatch::IntegrationTest
  test "exposes Rails request metrics locally" do
    get root_path
    get "/metrics"

    assert_response :success
    assert_includes response.body, "rails_requests_total"
    assert_includes response.body, "rails_request_duration_seconds_bucket"
  end
end
