# OpenStack High-Availability Cookbook

This cookbook is an automation framework that can be used to setup enterprise grade highly available OpenStack
environments. The goal of this framework is to be able to describe a distributed OpenStack deployment in a template
which can be shared within the community. It captures these various OpenStack topologies in templates, which can be
executed in a repeatable manner.

## Supported Platforms

TODO: ...

## Installation

http://rvm.io/
rvm list known
rvm install ruby-2.1.3
rvm use ruby-2.1.3

sudo gem install chef
sudo gem install knife-xenserver
sudo gem install knife-kvm
sudo gem install rbvmomi
sudo gem install knife-esx

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
Mevan Samaratunga | mevansam@gmail.com<br/> msamaratunga@pivotal.io | Pivotal
