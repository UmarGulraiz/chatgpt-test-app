OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_API_KEY')
  config.request_timeout = 240 # Optional
end
