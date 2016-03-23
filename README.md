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
  advertise_addr   => '192.168.0.2',
  controller_addrs => ['192.168.0.2'],
}
```

#### Worker
The `seed_stack::worker` class is responsible for configuring a Seed Stack worker. For a full list of available parameters, see the [class source](manifests/worker.pp).

```puppet
class { 'seed_stack::worker':
  advertise_addr   => '192.168.0.3',
  controller_addrs => ['192.168.0.2'],
}
```

#### Combination controller/worker
A node can be both a controller and a worker. This is useful for single-node setups.

```puppet
class { 'seed_stack::controller':
  advertise_addr    => $ipaddress_eth0,
  controller_addrs  => [$ipaddress_eth0],
  controller_worker => true,
}
class { 'seed_stack::worker':
  advertise_addr    => $ipaddress_eth0,
  controller_addrs  => [$ipaddress_eth0],
  controller_worker => true,
}
```
**NOTE:** For combination controller/workers it is necessary to set `controller_worker => true` for both the `seed_stack::controller` class and the `seed_stack::worker` class so that the two classes do not conflict.

#### External load balancers and routers
We use Nginx to load balance and route between containers. Sometimes it is useful to do this outside of the Mesos cluster itself. For instance, an external host could be the load balancer for a web service or some service running on the host could need to be routed to containers directly.

Nginx is dynamically configured using Consul Template in these cases. First, set that up:
```puppet
class { 'seed_stack::template_nginx':
  consul_address => '192.168.0.5', # Consul address for Consul Template to connect to
}
```
Then you can set up either set up a load balancer or a router (or both):
```puppet
include seed_stack::load_balancer
include seed_stack::router
```

#### Consul DNS
It's often useful to use Consul's DNS for service discovery on nodes that aren't controllers or workers. For example, a database node could advertise it's service to other nodes using Consul. To do this, use the `seed_stack::consul_dns` class. The class needs a few parameters so that it knows how to join the Consul cluster:
```puppet
class { 'seed_stack::consul_dns':
  advertise_addr => $ipaddress_eth0, # Address to advertise for services on this node
  join           => ['10.215.32.11', '10.215.32.12'], # List of any Consul nodes already in the cluster
}

consul::service { 'postgresql':
  port   => 5432,
  checks => [{
    script   => '/usr/bin/pg_isready',
    interval => '30s',
  }],
}
```
After the above example is applied, the address `postgresql.service.consul` is available in the Consul cluster and will point to the node's advertise address. For full documentation on all the configuration parameters available for Consul, see the [manifest source](manifests/consul_dns.pp).

## Upstream modules
We make use of quite a few Puppet modules to manage all the various pieces of software that make up Seed Stack. See the [metadata file](metadata.json) for a complete listing with version information.

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
| Mesos           | 0.27.2  |
| Marathon        | 0.15.3  |
| Zookeeper       | System  |
| Docker          | 1.10.3  |
| Consul          | 0.6.4   |
| Consular        | 1.2.0   |
| Consul Template | 0.14.0  |
| Nginx           | System  |
