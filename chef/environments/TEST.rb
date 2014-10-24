name "TEST"
description "Click2Compute OpenStack test."

encryption_key=File.read(File.absolute_path(File.dirname(__FILE__) + "/../secrets/TEST"))

override_attributes(
	"env" => {
		"encryption_key" => encryption_key,
		"http_proxy" => "http://http.proxy.fmr.com:8000",
		"domain" => "fmr.com"
	},
	"percona" => {
		"encrypted_data_bag" => "passwords.TEST"
	}
)
