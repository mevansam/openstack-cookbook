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

##Getting Started
## Supported Platforms

The tools and templates have been tested on the following platforms.

* Tools:
  * Mac OS X

* Vagrant Template:
  * VirtualBox on Mac OS X
  * VMware Fusion on Mac OS X

## Installation

The Knife Stackbuilder plugin executes jobs asynchronously and makes extensive use of threading. During testing it has been noticed that if installed within the ChefDK gem environment the plugin exits with a "deadlock" error. This does not exist within a regular Ruby 2.1.5 environment. So it is recommended that this plugin be installed within a Ruby environment managed by a Ruby version manager like RVM.

1. First create a Ruby 2.1.5 environment. For example using [RVM](http://rvm.io)

  ```
  $ curl -sSL https://get.rvm.io | bash -s stable
  $ rvm install 2.1
  ```

2. Install the [knife-stackbuilder](https://github.com/mevansam/chef-knife-stackbuilder) gem.

  ```
  $ gem install --no-document knife-stackbuilder
  $ gem install --no-document berkshelf
  ```
  
3. Clone this repository

  ```
  $ git clone https://github.com/mevansam/openstack-ha-cookbook.git
  $ cd openstack-ha-cookbook
  ```
  
4. If you plan to execute the vagrant templates then you need to get the updated
[vagrant-ohai](https://github.com/avishai-ish-shalom/vagrant-ohai) plugin for vagrant.

  ```
  $ vagrant plugin install vagrant-plugins/vagrant-ohai-0.1.8.gem
  ```
  
  > These patches and updates are in the process being pushed to their respective upstream repositories. The patched vagrant gem is available at:
  > * [vagrant-ohai](https://github.com/mevansam/vagrant-ohai.git)

5. Optional: create ```.chef``` folder and copy chef-zero knife configuration files if you plan to use chef-zero as you default chef.

  ```
  $ mkdir .chef
  $ cp etc/chef-zero_* .chef
  $ mv .chef/chef-zero_knife.rb .chef/knife.rb
  ```

6. The repository's ```scripts``` folder contains a few useful scripts to manage starting and stopping a local Chef-Zero as well as scripts to manage a local [logstash](http://logstash.net/) rsyslogd sink that will stream logs to local a [logio](http://logio.org/) server. If you start Chef-Zero using the scripts it will create the ```.chef``` folder and you can skip step 5.
 
  * In order to use logio you need to install node.js. It is recommended you use [nvm](https://github.com/creationix/nvm) 
    to manage your node install rather than the [installable packages](http://nodejs.org/download/) distributed by Joyent.

    Ensure the following is added to your default shell profile (.zlogin if you are using .zshrc), as the NVM install only
    adds it to the ```.bashrc``` file.
    
    ```
    export NVM_DIR="/Users/msamaratunga/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    ```
    
    Install node.js and then logio as follows.
    
    ```
    $ nvm install stable
    $ nvm use 0.10
    $ npm install -g log.io
    ```
  * Logstash requires the Java JDK to be installed in the system. You can download the latest logstash distribution from its
    [website](http://logstash.net/). Untar it to a known location and ensure that the ```[logstash home dir]/bin``` folder is
    added to the PATH environment variable.
 
  * You can also run [RabbitMQ](https://www.rabbitmq.com/download.html) and [MySql](http://dev.mysql.com/downloads/) as local
    services so you do not need to create a VM to host those services. In order to run these services locally you first need to
    install them into the local host and then make sure the system ```PATH``` variable is updated to include their ```bin```
    folders.
  
  To start Chef-Zero
  ```
  $ scripts/start_chef_zero.sh
  ```
  To stop Chef-Zero
  ```
  $ scripts/stop_chef_zero.sh
  ```
  To start log services. Once started the log.io streaming console will be available at
  [http://localhost:9081](http://localhost:9081). Make sure you provide the correct Chef environment for your build.
  ```
  $ scripts/start_log_servers.sh vagrant_kvm
  ```
  To stop log services.
  ```
  $ scripts/stop_log_servers.sh
  ```
  To start the Ops services (RabbitMQ and MySQL)
  ```
  $ scripts/start_ops_servers.sh vagrant_kvm
  ```
  To seed the MySQL databases.
  ```
  $ scripts/create_mysql_osdb.sh vagrant_kvm
  ```
  To stop log services.
  ```
  $ scripts/stop_ops_servers.sh
  ```
  To restart all of the above via a single script.
  ```
  $ scripts/reset_all.sh vagrant_kvm
  ```

 > Both steps 5. and 6. are relevant only if you plan to build the vagrant templates.
 
7. If you want to setup the OpenStack CLI tools to interact with OpenStack via the command line, then create a python virtual environment and install the python clients as follows.

  * Create work area and cd to it. This should not be inside the openstack-ha-cookbook repo.
  
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
  $ pyos/bin/pip install virtualenv-1.11.tar.gz
  $ rm -fr virtualenv-1.11.tar.gz
  ````

  * Activate the virtual environment and install the clients
    
  ````
  $ source pyos/bin/activate
  $ pip install python-keystoneclient python-glanceclient python-cinderclient python-neutronclient python-novaclient
  ````

  Once you have setup the openstack environment copy the `openrc` file created on the controller host to this work
  area and source it before calling the OpenStack APIs via the client tools.
  
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

  To execute a stack simply determine which stack you want to build for a specific environment and run the following. If you have added a default knife configuration you can omit the -c argument. 

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

  ```
  # Run Chef-Zero
  $ scripts/start_chef_zero.sh

  # Load Chef-Zero
  $ knife stack upload repo -c etc/chef-zero_knife.rb

  # Build the stack
  $ knife stack build stack_vbox_qemu --environment=vagrant_kvm --stack-id msam -V -c etc/chef-zero_knife.rb
  ```

  If the stack build completes successfully, horizon will be available at
  [https://192.168.60.200](https://192.168.60.200), and you can login with the credentials ```admin/0p3n5tack```.

  From a shell provisioned with the OpenStack CLI, use the following gists to initialize the OpenStack environment.
  * [Sample openrc for the Vagrant stack](https://gist.github.com/mevansam/d0d517ea321c6b199e55)
  * [Script to upload an image, create a network and import your ssh public key](https://gist.github.com/mevansam/2b8ee9e248d1b5082552)

3. When you are done you can delete the entire cluster by running the following command:

  ```
  $ knife stack delete stack_vbox_qemu --environment=vagrant_kvm --stack-id msam -V -c etc/chef-zero_knife.rb
  ```

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

### The Repository Structure

The repository structure is based off the [chef-repo](http://docs.getchef.com/chef_repo.html) structure used for Chef
development. You can managed it via Knife and [Berkshelf](http://berkshelf.com/v2.0/). For data bags you need to use
```knife stack upload data bags ...```, so that they are created and encrypted by environment. At a high level the 
following diagram outlines the relationship between the various files in the repo and how they contributed to the final
execution environment.

![Image of OpenStack HA Configuration File Structure]
(docs/images/config_files.png)

The high-lighted files create the static Chef environment, whereas the Stack File can introduce variability to the
deployment. The high-lighted arrows imply that variable substition happens automatically based on the selected Chef
environment.

### OpenStack KVM on Vagrant Template

#### Basic Environment in Vagrant

![Image of OpenStack KVM setup on Vagrant]
(docs/images/vagrant_kvm.png)

This vagrant template can be used to launch a minimal OpenStack QEMU/KVM node. It builds a 10G vagrant VM so you have
sufficient space on the compute node to test products that can be deployed to OpenStack. For example Bosh/CloudFoundry.

#### Simulated HA Environment in Vagrant

![Image of OpenStack HA KVM setup on Vagrant]
(docs/images/vagrant_hakvm.png)

This Vagrant template can be used to launch a minimal OpenStack HA cluster using a nested hypervisor on either Virtual
Box or VMware. The HAProxy nodes as well as the Compute nodes are setup as Pacemaker clusters and Percona MySQ and Rabbit MQ
will deploy as single node clusters unless scaled up. The Chef OpenStack environment for this minimal environment is described
in ```environments/vagrant_kvm```. The two stack files for VirtualBox and VMWare are ```stack_vbox_qemu.yml``` and
```stack_vmware_kvm.yml``` respectively. It should be noted that, although the environment attributes will by default setup
KVM, the VirtualBox stack template overrides KVM with Qemu, as VirtualBox does not expose the processor extensions to guests
required to run a nested hypervisor. You will need at a minimimum 7GB of memory available on the host to launch the stack and
more if you want to scale it out. This template can be used purely to test an HA OpenStack configuration and scale out via the
StackBuilder plugin, but it is not very useful beyond that.

#### Troubleshooting

1. If the build fails with a cookbook error it is safe to re-run it. Sometimes failures can occur due to time-outs
when downloading binaries from the internet, if you are on a very slow connection or the public repository servers
are overloaded.

2. If VM creation is halted this leaves the Knife Vagrant plugin's VM directory in a bad state. If this happens you
need to delete them via the VirtualBox UI or in the case of VMWare kill the VM processes. Once deleted
delete their meta-data folders in the ~/.vagrant folder.

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
Josh Kruck | jkruck@pivotal.io | [Pivotal](http://www.pivotal.io)
