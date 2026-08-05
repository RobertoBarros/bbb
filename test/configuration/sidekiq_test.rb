require "test_helper"

class SidekiqTest < ActiveSupport::TestCase
  test "uses the test adapter in the test environment" do
    assert_instance_of ActiveJob::QueueAdapters::TestAdapter, ActiveJob::Base.queue_adapter
  end

  test "starts with an empty cron schedule" do
    schedule_path = Rails.root.join("config/schedule.yml")

    assert_equal schedule_path.to_s, Sidekiq::Cron.configuration.cron_schedule_file
    assert_empty YAML.safe_load_file(schedule_path)
  end
end
