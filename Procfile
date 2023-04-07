web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q default
release: rake db:migrate
