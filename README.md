# OpenStack High-Availability Cookbook

This cookbook is an automation framework that can be used to setup enterprise grade highly available OpenStack
environments. The goal of this framework is to be able to describe a distributed OpenStack deployment in a template
which can be shared with the community. It captures these various OpenStack topologies in templates, which can be
executed in a repeatable manner.

## Supported Platforms

TODO: ...

## Installation

You can run this framework by installing the required Chef configuration tools within your rvm/rubyenv environments
or within a ChefDK environments. The recommended approach described below sets up the required additional tools
within a ChefDK environment.

1. First download and install the latest [ChefDK](https://downloads.getchef.com/chef-dk/). This will give you a self
contained ruby environment. If you have other ruby environments managed by rvm/rubyenv, you can manage which one to
use based on your current directory using [direnv](http://direnv.net/).

2. Install the knife-stackbuilder gem.

	```
	$ gem install knife-stackbuilder
	```
3. If you plan to execute the vagrant templates then you need to get the
[knife-vagrant2](https://github.com/makern/knife-vagrant2) plugin for knife and the
[vagrant-ohai](https://github.com/avishai-ish-shalom/vagrant-ohai) plugin for vagrant. However, instead of the
original the following patched/updated plugins need to be installed as follows.

    > These patches and updates are in the process being pushed to their respective upstream repositories.

4. 



### OpenStack KVM on Vagrant Template

![Image of OpenStack KVM setup on Vagrant]
(docs/images/vagrant_kvm.png)

### OpenStack KVM on VMWare Template

TODO: ...

### OpenStack HA KVM Template

TODO: ...

### OpenStack HA VMWare ESX Template

TODO: ...

### OpenStack HA XenServer Template

TODO: ...

### OpenStack HA HyperV Template

TODO: ...

### OpenStack HA Multi-Hypervisor Template

## Design

TODO: ...

## Extending

TODO: ...

## Contributing

1. Fork the repository on Github
2. Write your change
3. Write tests for your change (if applicable)
4. Run the tests, ensuring they all pass
5. Submit a Pull Request

## License and Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Author | Email | Company
-------|-------|--------
Mevan Samaratunga | msamaratunga@pivotal.io | Pivotal
