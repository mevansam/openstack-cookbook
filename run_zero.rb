require 'chef_zero/server'
if system("lsof -i:9999", out: '/dev/null')
	puts "Seems like port 9999 is already in use..."
else
	server = ChefZero::Server.new(host: '0.0.0.0', port: 9999, debug: true)
	server.start
end

