# yabeda-rails detects `rails server` automatically. Tests boot the application
# directly, so they need to register the same metrics explicitly.
Yabeda::Rails.install! if Rails.env.test?
