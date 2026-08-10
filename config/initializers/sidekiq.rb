redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server do |config|
  config.redis = redis_config

  Yabeda::Prometheus::Exporter.start_metrics_server! if Rails.env.local? || ENV["METRICS_ENABLED"] == "true"
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

Sidekiq::Cron.configure do |config|
  config.cron_schedule_file = Rails.root.join("config/schedule.yml").to_s
  config.cron_poll_interval = 5
end
