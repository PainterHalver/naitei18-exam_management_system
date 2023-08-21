# Run production mode

```shell
# Prepare database
RAILS_ENV=production rails db:{create,migrate:reset,seed}

# Compile assets
RAILS_ENV=production rails assets:{clobber,precompile} webpacker:compile

# Run server
RAILS_ENV=production rails s
```
