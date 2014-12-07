require 'chef_zero/server'
server = ChefZero::Server.new(host: '0.0.0.0', port: 9999, debug: true)
server.start

