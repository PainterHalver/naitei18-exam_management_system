Rack::Attack.enabled = true
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# Allow all local traffic (blocklist & throttles are skipped)
Rack::Attack.safelist('allow-localhost') do |req|
  req.ip == "127.0.0.1" || req.ip == "::1"
end

### Throttle Spammy Clients ###
# If any single client IP is making tons of requests, then they're
# probably malicious or a poorly-configured scraper. Either way, they
# don't deserve to hog all of the app server's CPU. Cut them off!
Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes) do |req|
  req.ip unless req.path.start_with?('/assets')
end

# Throttle requests to 10 requests per minute per ip from login endpoint
Rack::Attack.throttle('Requests by ip', limit: 10, period: 1.minute) do |req|
  # /api/v1/auth/login.{format} and /{en,vi,}/login.{format}
  if (req.path =~ %r{^/api/v1/auth/login} || req.path =~ %r{^(/en|/vi|)/login}) && req.post?
    req.ip
  end
end

# Custom Throttle Response
Rack::Attack.throttled_responder = lambda do |request|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 429 for throttling by default
  [ 503, {}, ["Server Error\n"]]
end
