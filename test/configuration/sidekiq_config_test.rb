require "test_helper"

class SidekiqConfigTest < ActiveSupport::TestCase
  test "limits Sidekiq to two threads by default" do
    config = YAML.safe_load(ERB.new(Rails.root.join("config/sidekiq.yml").read).result, permitted_classes: [ Symbol ])

    assert_equal 2, config.fetch(:concurrency)
  end
end
