class KnifeVspherePlugin

	attr_accessor :data

	def customize_clone_spec(src_config, clone_spec)
	
		puts "Src clone_spec object :\n #{YAML::dump(clone_spec)}"
		puts "New clone_spec object :\n #{YAML::dump(clone_spec)}"
		exit 1
	end

	def reconfig_vm(target_vm)
	end
end