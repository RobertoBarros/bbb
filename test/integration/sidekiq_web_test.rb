require "test_helper"

class SidekiqWebTest < ActionDispatch::IntegrationTest
  test "dashboard is available with the cron extension" do
    get "/sidekiq"

    assert_response :success
    assert_select "a[href='/sidekiq/cron']"
  end
end
