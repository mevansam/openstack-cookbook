# OpenStack High-Availability Cookbook

This cookbook is an automation framework that can be used to setup enterprise grade highly available OpenStack
environments. The goal of this framework is to be able to describe a distributed OpenStack deployment in an
executable template which can be shared with the community.

## Design & Use

This cookbook evolved from an effort to make it easier to use the OpenStack Chef cookbooks available on
[StackForge](https://github.com/stackforge). It was modeled after the
[OpenStack Chef Repo](https://github.com/stackforge/openstack-chef-repo) and borrows heavily from its collection of
Chef roles. However instead of SpiceWeasel it uses a custom Knife plugin called
[Knife StackBuilder](https://github.com/mevansam/chef-knife-stackbuilder) to interact with the Chef Server to build
the cluster using a topology described in a YAML file.

The StackBuilder plugin executes the topology by executing additional knife calls using knife cloud plugins to
bootstrap hosts and apply and customize their run-lists. During execution the plugin requires a path to a standard
Chef repo folder. It can also invoke Berkshelf to bulk upload cookbooks and perform other tasks such as creating the
Chef environment and uploading roles and encrypted data bags. It enforces a particular standard when processing the
data files to enable externalizing the Chef environment and data bag attributes to support multiple custom
configurations with a single environment template. This allows you to simplify the complexity of building the Chef
environment required by the Stackforge cookbooks to build an OpenStack cluster.

It was created in favor of leveraging SpiceWeasel or Chef-Provisioning to address the following:

* Externalize a Chef environment so it can be templatized and customized based on the executing shell environment and
 a source environment variables file.

* Ability to describe dependencies between various nodes in the topology and execute in order.

* Be able to modify the Chef nodes attributes at execution time.

* Create a mode around using certificates (and creation of self-signed certificates) to setup SSL as well as securing
 all data in Data Bags via encryption using a key per environment (integration with Chef-Vault is coming).

* Simplify the build steps to 'upload Chef repo', 'build stack', 'interact with the stack', ... etc.

Think of StackBuilder as a Ansible or SaltStack for Chef Knife.

### The Repository Structure

The repository structure is based off the [chef-repo](http://docs.getchef.com/chef_repo.html) structure used for Chef
development. The only difference being that it favors using [Berkshelf](http://berkshelf.com/v2.0/) to manage
cookbooks and data bags are created by environment when uploaded via StackBuilder. At a high level the following
diagram outlines the relationship between the various files in the repo and how they contributed to the final
execution environment.

![Image of OpenStack HA Configuration File Structure]
(docs/images/config_files.png)

The high-lighted files create the static Chef environment, whereas the Stack File can introduce variability to the
deployment. The high-lighted arrows imply that variable substition happens automatically based on the selected Chef
environment.

### Inspecting the environment

It is useful to inspect the environment when troubleshooting a deployment. The following snippets assume
[Chef Zero](https://github.com/opscode/chef-zero) is running in the localhost.

> To run chef zero execute ```ruby run_zero.rb``` from within this repositories folder.
> You can then use the knife configuration at 'etc/chef-zero_knife.rb' to interact with it.

1. The Chef Environment

	First upload the Chef environment to chef server

	```
	$ knife stack upload environments --environment=vagrant_kvm -c etc/chef-zero_knife.rb

	Uploaded environment 'vagrant_kvm' to 'http://192.168.1.10:9999'.

	```
	Inspect the environment

	```
	$ knife environment show vagrant_kvm -c etc/chef-zero_knife.rb

    chef_type:           environment
    cookbook_versions:
    default_attributes:
    description:         HA OpenStack Environment.
    json_class:          Chef::Environment
    name:                vagrant_kvm
    override_attributes:
    .
    .
    .

	```

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
