## 0.2.3 - UNRELEASED
### Changes
* deric/zookeeper module version 0.4.2 - Zookeeper `maxClientCnxns` is no longer set. The default is used. This should have no effect as we were previously setting it to the default. (#21)
* Default the `hostname` parameter to `$::fqdn`. This makes it easier for Marathon/Mesos/Nginx to look up other nodes, especially on a public network (although you probably shouldn't be doing that). (#24)

## 0.2.2 - 2016/01/14
### Changes
* Mesos master `advertise_ip` now set to `address` (#19)

### Fixes
* Marathon module updated to 0.2.2 with fixes (#23)

## 0.2.1 - 2016/01/12
### Changes
* Source praekeltfoundation modules from Puppet Forge (#10)

## 0.2.0 - 2016/01/12
### Features
* `seed_stack::load_balancer` added for exposing services externally (#11)
* Mesos listen address now configurable (#13)
* Consul health checks for Mesos, Marathon and Zookeeper (#9)
* Zookeeper listen address now configurable (#17)

### Changes
* Node address and hostname default to `$::ipaddress_lo` and `$::hostname`, respectively. (#14)
* Mesos listen address defaults to `0.0.0.0` (#13)
* Zookeeper listen address defaults to `0.0.0.0` (#17)
* Combination controller/worker nodes must now set `controller_worker => true` for both `seed_stack::controller` and `seed_stack::worker` classes. (#15)
* Use git to fetch praekeltfoundation modules (#16)
* Zookeeper `maxClientCnxns` now set to 60, up from 10 (#17)

### Fixes
* Ensure apt-get has updated before installing Mesos on a worker (#12)
* Fix installing Consul on a worker due to missing unzip package (#12)
* Stop `mesos-slave` service from running on controller and `mesos-master` from running on worker (#15)
* Add `mesos-slave` Consul service to combination controller/worker (#15)
* Fix Consul on workers by removing `bootstrap_expect` (#15)
* Determine and set Zookeeper ID correctly (#17)

## 0.1.0 - 2016/01/08
**Initial release**
* `seed_stack::controller` to set up a controller
* `seed_stack::worker` to set up a worker
* Tested on a standalone combination controller/worker only
