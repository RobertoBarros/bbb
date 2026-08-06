require "test_helper"

class SidekiqTest < ActiveSupport::TestCase
  CRON_JOB_NAME = "refresh_election_results".freeze

  setup do
    Sidekiq::Cron::Job.destroy(CRON_JOB_NAME)
  end

  teardown do
    Sidekiq::Cron::Job.destroy(CRON_JOB_NAME)
  end

  test "uses the test adapter in the test environment" do
    assert_instance_of ActiveJob::QueueAdapters::TestAdapter, ActiveJob::Base.queue_adapter
  end

  test "configures the election tally cron schedule" do
    schedule_path = Rails.root.join("config/schedule.yml")

    assert_equal schedule_path.to_s, Sidekiq::Cron.configuration.cron_schedule_file
    assert_equal 5, Sidekiq::Cron.configuration.cron_poll_interval
    assert_equal(
      {
        "refresh_election_results" => {
          "cron" => "*/5 * * * * *",
          "class" => "RefreshElectionResultsJob",
          "active_job" => true,
          "queue" => "results"
        }
      },
      YAML.safe_load_file(schedule_path)
    )
  end

  test "loads the election tally cron job" do
    Sidekiq::Cron::ScheduleLoader.new.load_schedule

    job = Sidekiq::Cron::Job.all.find { |cron_job| cron_job.name == CRON_JOB_NAME }

    assert_equal "*/5 * * * * *", job.cron
    assert_equal "RefreshElectionResultsJob", job.klass
    assert_equal "results", Sidekiq.load_json(job.message).fetch("queue")
  end
end
