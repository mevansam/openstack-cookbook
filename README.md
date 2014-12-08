# OpenStack High-Availability Cookbook

This cookbook is an automation framework that can be used to setup enterprise grade highly available OpenStack
environments. The goal of this framework is to be able to describe a distributed OpenStack deployment in an
executable template which can be shared with the community.

## Supported Platforms

The tools and templates have been tested on the following platforms.

* Tools:
	* Mac OS X

* Vagrant Template:
	* VirtualBox on Mac OS X
	* VMware Fusion on Mac OS X

## Installation

You can run this framework by installing the required Chef configuration tools within your rvm/rubyenv environments
or within a ChefDK environments. The recommended approach described below sets up the required additional tools
within a ChefDK environment.

1. First download and install the latest [ChefDK](https://downloads.getchef.com/chef-dk/). This will give you a self
contained ruby environment. If you have other ruby environments managed by rvm/rubyenv, you can manage which one to
use based on your current directory using [direnv](http://direnv.net/).

2. Install the [knife-stackbuilder](https://github.com/mevansam/chef-knife-stackbuilder) gem.

	```
	$ gem install -​-no-document knife-stackbuilder
	```
3. Clone this repository

	```
	$ git clone https://github.com/mevansam/openstack-ha-cookbook.git
	$ cd openstack-ha-cookbook
	```
4. If you plan to execute the vagrant templates then you need to get the updated
[knife-vagrant2](https://github.com/makern/knife-vagrant2) plugin for knife and the
[vagrant-ohai](https://github.com/avishai-ish-shalom/vagrant-ohai) plugin for vagrant.

	```
	$ gem install --no-document vagrant-plugins/knife-vagrant2-0.0.5.gem
	$ vagrant plugin install vagrant-plugins/vagrant-ohai-0.1.8.gem
	```
    > These patches and updates are in the process being pushed to their respective upstream repositories. The patched gems are available at:
    > * [knife-vagrant2](https://github.com/mevansam/chef-knife-vagrant2.git)
    > * [vagrant-ohai](https://github.com/mevansam/vagrant-ohai.git)

5. If you want to setup the OpenStack CLI tools to interact with OpenStack via the command line, then create a python
virtual environment and install the python clients as follows.

	* Create work area and cd to it

	```
	$ mkdir -p [your workspace]/openstack-cli
	$ cd [your workspace]/openstack-cli
	```
	* Install the python virtual environment

	````
	$ curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-1.11.tar.gz
    $ tar xvf virtualenv-1.11.tar.gz
    $ python virtualenv-1.11/virtualenv.py pyos
    $ rm -rf virtualenv-1.11
    $ yos/bin/pip install virtualenv-1.11.tar.gz
    $ rm -fr virtualenv-1.11.tar.gz
    ````

	* Activate the virtual environment and install the clients
	````
    $ source pyos/bin/activate
    $ pip install python-keystoneclient
    $ pip install python-glanceclient
    $ pip install python-cinderclient
    $ pip install python-neutronclient
    $ pip install python-novaclient
    ```

	Once you have setup the openstack environment copy the `openrc` file created on the controller host to this work
	area and source it before calling the OpenStack APIs via the client tools.

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

### OpenStack Highly Available Multi-Hypervisor Template

TODO: ...

### OpenStack DevStack Vagrant Template with PyDevd

TODO: ...

## Design

TODO: ...

## Extending

TODO: ...

## Contributing

1. Fork the repository on Github
2. Create and test the template
3. Document how to use the template
4. Submit a Pull Request

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
Mevan Samaratunga | msamaratunga@pivotal.io | [Pivotal](http://www.pivotal.io)
