# puppet-seed_stack
Puppet meta-module for deploying the Seed Stack. This module uses other Puppet modules to install all the basic parts of Praekelt Foundation's Seed Stack.

The module installs and configures:
* [Mesos](https://mesos.apache.org/)
* [Marathon](http://mesosphere.github.io/marathon/)
* [Zookeeper](https://zookeeper.apache.org/)
* [Docker](https://www.docker.com)
* [Consul](http://consul.io)
* [Consular](http://consular.rtfd.org)
* [Consul Template](https://github.com/hashicorp/consul-template)
* [Nginx](http://www.nginx.org)
* ...and a few miscellaneous things like Dnsmasq to tie them together

This module is not designed for complete configurability of the stack and instead takes an opinionated approach to setting up all the parts of the system to work together. This module should be the quickest way to set up a Seed Stack cluster (or even a standalone development host).

To try out Seed Stack, a Vagrant Box is available [here](https://github.com/praekelt/seed-stack).

This module was designed for use on Ubuntu 14.04.

## Work in progress
This module is still a **work in progress**. We are waiting on new releases of a few of its dependencies. Some things are not done as nicely as they could be yet. There are no tests.

## Usage
A Seed Stack node can either be a controller (i.e. a Mesos master), a worker (a Mesos slave), or a combination of the two.

#### Controller
The `seed_stack::controller` class is responsible for configuring a Seed Stack controller. For a full list of available parameters, see the [class source](manifests/controller.pp).

```puppet
class { 'seed_stack::controller':
  address              => $ipaddress_eth0,
  controller_addresses => [$ipaddress_eth0],
}
```

#### Worker
The `seed_stack::worker` class is responsible for configuring a Seed Stack worker. For a full list of available parameters, see the [class source](manifests/worker.pp).

```puppet
class { 'seed_stack::worker':
  address    => $ipaddress_eth0,
}
```

#### Combination controller/worker
A node can be both a controller and a worker. This is useful for single-node setups.

```puppet
class { 'seed_stack::controller':
  address              => $ipaddress_eth0,
  controller_addresses => [$ipaddress_eth0],
  controller_worker    => true,
}
class { 'seed_stack::worker':
  address           => $ipaddress_eth0,
  controller_worker => true,
}
```
**NOTE:** For combination controller/workers it is necessary to set `controller_worker => true` for both the `seed_stack::controller` class and the `seed_stack::worker` class so that the two classes do not conflict.

#### Load balancers
If you need to expose apps running on Seed Stack to the outside world, Nginx can be used to load-balance between app instances and expose the apps from an accessible endpoint. To set up Nginx to be dynamically configured to do this, use the `seed_stack::load_balancer` class.

```puppet
include seed_stack::load_balancer
```
Different parts of the class can be disabled if the node it is being included on already has Nginx or Consul Template installed. See the [manifest source](manifests/load_balancer.pp) for more information.

## Upstream modules
We make use of quite a few Puppet modules to manage all the various pieces of software that make up Seed Stack. See the [Puppetfile](Puppetfile) for a complete listing with version information.

Firstly, we wrote some modules ourselves:
* [praekeltfoundation/consular](https://forge.puppetlabs.com/praekeltfoundation/consular)
* [praekeltfoundation/marathon](https://forge.puppetlabs.com/praekeltfoundation/marathon)
* [praekeltfoundation/webupd8_oracle_java](https://forge.puppetlabs.com/praekeltfoundation/webupd8_oracle_java)

Then there are some 3rd party modules:
* [deric/mesos](https://forge.puppetlabs.com/deric/mesos)
* [deric/zookeeper](https://forge.puppetlabs.com/deric/zookeeper)
* [garethr/docker](https://forge.puppetlabs.com/garethr/docker)
* [gdhbashton/consul_template](https://forge.puppetlabs.com/gdhbashton/consul_template)
* [KyleAnderson/consul](https://forge.puppetlabs.com/KyleAnderson/consul)

## Java 8
Java 8 is a dependency of Marathon version 0.12.0+. Ubuntu 14.04 does not have a package for this in the standard repositories. `seed_stack::controller` will install [Oracle Java 8 from the WebUpd8 PPA](https://github.com/praekeltfoundation/puppet-webupd8_oracle_java). This can be disabled by passing `install_java => false`.

Note that Java is also a dependency of Mesos and Zookeeper. If you are managing your own Java installation you should ensure that Java is installed before any of the packages that depend on it so as to prevent multiple versions of Java being installed.

## Default package versions
The package versions can be seen in the [params class source](manifests/params.pp). All of these versions can be adjusted using parameters in the controller and worker classes. These versions are reasonably well-tested and known to work together.

| Package         | Version |
|-----------------|---------|
| Mesos           | 0.24.1  |
| Marathon        | 0.13.0  |
| Zookeeper       | System  |
| Docker          | 1.9.1   |
| Consul          | 0.6.1   |
| Consular        | 1.2.0   |
| Consul Template | 0.12.0  |
| Nginx           | System  |
