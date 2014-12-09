# OpenStack High-Availability Cookbook

This cookbook is an automation framework that can be used to setup enterprise grade highly available OpenStack
environments. The goal of this framework is to be able to describe a distributed OpenStack deployment in an
executable template which can be shared with the community.

> This README assumes that you are familiar with the Chef automation
> framework and the basics of using Knife to interact with a Chef Server.

## Overview

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

* Leverage [Chef Knife community plugins](https://docs.getchef.com/community_plugin_knife.html) to target multiple
clouds.

* Create a model around using certificates (and creation of self-signed certificates) to setup SSL as well as securing
all data in Data Bags via encryption using a key per environment (integration with Chef-Vault is coming).

* Simplify the build steps to 'upload Chef repo', 'build stack', 'interact with the stack', ... etc.

Think of StackBuilder as an Ansible or SaltStack for Chef Knife.

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

> To run chef zero execute ```ruby run_zero.rb``` from within this repository's folder.
> You can then use the knife configuration at 'etc/chef-zero_knife.rb' to interact with it.

1. The Chef Environment

	First upload the Chef environment to Chef server

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

2. Data bags

	First upload the data bag for a specific environment to the Chef server

	```
	$ knife stack upload data bags --data-bag=os_db_passwords --environment=vagrant_kvm -c etc/chef-zero_knife.rb

    Uploaded item 'ceilometer' of data bag 'os_db_passwords-vagrant_kvm' to 'http://192.168.1.10:9999'.
    Uploaded item 'cinder' of data bag 'os_db_passwords-vagrant_kvm' to 'http://192.168.1.10:9999'.
    .
    .
    .
	```
	Show data bags

	```
	$ knife data bag list -c etc/chef-zero_knife.rb

    certificates-vagrant_kvm
    os_db_passwords-vagrant_kvm
    os_secrets-vagrant_kvm
	.
	.
	.
	```
	Inspect a data bag item

	```
	$ knife data bag show os_db_passwords-vagrant_kvm horizon --secret-file=secrets/vagrant_kvm -c etc/chef-zero_knife.rb

	horizon: 0p3n5tack
    id:      horizon
    ```

3. The Stack

	Run the following to show the parsed Stack file. This will show the complete stack file with all the includes and
	externalized variables resolved.

	```
	$ knife stack build stack_vbox_qemu --show-stack-file --environment=vagrant_kvm --stack-id msam -c etc/chef-zero_knife.rb

	Stack file:
    ---
    name: vbox_qemu
    vagrant:
      provider: virtualbox
      box_name: chef/ubuntu-14.04
      box_url: https://vagrantcloud.com/chef/boxes/ubuntu-14.04
    stack:
    - node: openstack-proxy
    .
    .
    .
	Stack build for '.../openstack-ha-cookbook/stack_vbox_qemu.yml' took 30 minutes and '12.020' seconds
	```

### Building a stack

1. Preparation

	Before the stack can be built the Chef repository needs to be uploaded. The following stack command loads the
	entire repository. It is simply a combination of individual stack repo commands executed in bulk for a specific
	Chef environment. This will also upload all the cookbooks specified in the Berkshelf file.

	```
	$ knife stack upload repo --environment=vagrant_kvm -c etc/chef-zero_knife.rb

	Resolving cookbook dependencies...
    Fetching 'network' from source at ../chef/network
    Fetching 'openstack-block-storage' from source at ../chef/openstack-block-storage
    Fetching 'openstack-compute' from source at ../chef/openstack-compute
    Fetching 'openstack-dashboard' from source at ../chef/openstack-dashboard
    Fetching 'openstack-identity' from source at ../chef/openstack-identity
    Fetching 'openstack-image' from source at ../chef/openstack-image
    Fetching 'openstack-network' from source at ../chef/openstack-network
    Fetching 'openstack-services' from source at ../chef/openstack-services
    Fetching 'sysutils' from source at ../chef/sysutils
	.
	.
	.
	Uploaded item 'aws' of data bag 'service_endpoints-vagrant_kvm' to 'http://192.168.1.10:9999'.
    Uploaded item 'qip' of data bag 'service_endpoints-vagrant_kvm' to 'http://192.168.1.10:9999'.
    Uploaded item 'root' of data bag 'users-vagrant_kvm' to 'http://192.168.1.10:9999'.
    Uploaded 'vagrant_kvm' certificate for server 'vagrant_kvm.mydomain.org' to data bag 'certificates-vagrant_kvm' at 'http://192.168.1.10:9999'.
	```

2. Execution

	To execute a stack simply determine which stack you want to build for a specific environment and run the following.

	```
	$ knife stack build stack_vbox_qemu --environment=vagrant_kvm --stack-id msam -c etc/chef-zero_knife.rb

	Uploaded environment 'vagrant_kvm' to 'http://192.168.1.10:9999'.
    Creating node resource 'openstack-proxy[0]'.
	.
	.
	.
	```
	The ```stack-id``` is a unique identifier for the stack you are building. Knife uses this ID to locate all nodes
	belonging to the OpenStack cluster to determine current state. If one is not provided a uuid will be generated as
	the for the ID.

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

The Vagrant template can be used to launch a minimal OpenStack cluster using a nested hypervisor on either Virtual
Box or VMware. The Chef OpenStack environment for this minimal environment is described in
```environments/vagrant_kvm```. The two stack files for VirtualBox and VMWare are ```stack_vbox_qemu.yml``` and
```stack_vmware_kvm.yml``` respectively. It should be noted that, although the environment attributes will by default
setup KVM, the VirtualBox stack template overrides KVM with Qemu, as VirtualBox does not expose the processor extensions
to guests required to run a nested hypervisor. You will need at a minimimum 7GB of memory available on the host to
launch the stack and more if you want to scale it out.

To execute the VirtualBox template from the repository folder:

```
# Run Chef-Zero
$ ruby run_zero.rb

# Load Chef-Zero
$ knife stack upload repo -c etc/chef-zero_knife.rb

# Build the stack
$ knife stack build stack_vbox_qemu --environment=vagrant_kvm --stack-id msam -V -c etc/chef-zero_knife.rb
```

If the stack build completes successfully horizon will be available at [https://192.168.60.200](https://192.168.60
.200), and you can login with the credentials ```admin/0p3n5tack```.

From a shell provisioned with the OpenStack CLI, use the following gists to initialize the OpenStack environment.
* [Sample openrc for the Vagrant stack](https://gist.github.com/mevansam/d0d517ea321c6b199e55)
* [Script to upload an image, create a network and import your ssh public key](https://gist.github.com/mevansam/2b8ee9e248d1b5082552)

> If you execute this template with Chef Zero remember to upload the repo to Chef-Zero before execution.
> Since Chef-Zero is an in-memory minimal Chef server if you restart the process then you need to reload it.

#### Troubleshooting

1. If the build fails with a cookbook error it is safe to re-run it. Sometimes failures can occur due to time-outs
when downloading binaries from the internet, if you are on a very slow connection or the public repository servers
are overloaded.

2. If VM creation is halted this leaves the Knife Vagrant plugin's VM directory in a bad state. If this happens you
need to delete them via the VirtualBox UI or in the case of VMWare kill the VM processes. Once deleted
delete their meta-data folders in the ~/.vagrant folder.

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
