name "PROD_MMK"
description "Click2Compute OpenStack MMK production."

encryption_key=File.read(File.absolute_path(File.dirname(__FILE__) + "/../secrets/PROD_MMK"))

override_attributes(
	"env" => {
		"encryption_key" => encryption_key,
		"http_proxy" => "http://http.proxy.fmr.com:8000",
		"domain" => "fmr.com"
	},
	"percona" => {
		"encrypted_data_bag" => "passwords.PROD_MMK"
	}
)
