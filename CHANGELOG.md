## 0.6.2 - 2016/03/03
### Changes
* Package versions now pinned to full version strings - NOTE: versions now platform specific (#78)

### Fixes
* Changed Dnsmasq `servicehost` entry from `address` to `host-record` (#73)
* Pin package versions to complete version strings to prevent service restarts (#77)

## 0.6.1 - 2016/03/02
### Fixes
* Fix Consul DNS lookup via Dnsmasq in certain cases (#72)

## 0.6.0 - 2016/02/24
### Features
* Add `redis_host` option for Xylem (#68)

## 0.5.0 - 2016/02/23
### Features
* Initial xylem support (#65)
* Docker 1.10.2 (#66)
* Mesos 0.27.1 (#66)
* Marathon 0.15.3 (badf8e9)
* Consul Template 0.13.0 (#63)

### Changes
* Consul working directory is now `/var/lib/consul` (#58)
* `deric/zookeeper` Puppet module updated to `0.5.1` (#64)

### Fixes
* Some basic tests (#57, #3, #65)

## 0.4.0 - 2016/02/09
### Features
* Dnsmasq host alias (`servicehost`) on all workers and controllers (#25, #46)
* Nginx service router address, port and domain now configurable (#44)
* Docker 1.10.0 (#47)
* Mesos 0.27.0 (#35)
* Marathon 0.15.1 (#51)
* Marathon syslog output is now suppressed (#54)
* README improvements (#48)
* Setting up a cluster now only requires the controllers being able to resolve the hostnames of workers (no other lookups are required) (#35)

### Changes
* `controller_addresses` -> `controller_addrs`, `address` -> `advertise_addr` (#50)
* `controller_addrs` and `advertise_addr` are now required parameters for controllers and workers (#49)
* Host `advertise_addr` used as Docker DNS address which means things should provision in a single Puppet run (#43)
* `deric/mesos` Puppet module updated to `0.6.5` (#40)
* `praekeltfoundation/marathon` Puppet module updated to `0.4.0` (#54)

### Fixes
* Nginx service router template properly parses `internal` boolean value (#44)
* Worker hostname defaults to `$::fqdn` like controllers (#35)
* Nginx service router actually works now (#25, #35, #44, #45)

## 0.3.0 - 2016/01/20
### Features
* `seed_stack::consul_dns` class makes it easy to set up Consul with DNS on a node outside the Mesos cluster (#32)
* Marathon 0.14.0 and Mesos 0.26.0 (#34)

### Changes
* Simplified Mesos service management (#27)
* Changes to the way `seed_stack::load_balancer` is structured that affect configuration (#28)
* praekeltfoundation/consular 0.2.0 module (#29)
* Consul 0.6.3 and Consul Template 0.12.2 (#30)
* Greater use of Puppet stdlib functions instead of `inline_template` (#33)

### Fixes
* Dnsmasq should now work when Consul listen address is not localhost (#26)
* Consular should now work when the Consul listen address is not localhost (#29)
* Unzip should now definitely be installed before installing Consul or Consul Template (#32, #36)

## 0.2.3 - 2016/01/15
### Changes
* deric/zookeeper module version 0.4.2 - Zookeeper `maxClientCnxns` is no longer set. The default is used. This should have no effect as we were previously setting it to the default. (#21)
* Consul Template 0.12.1 (#22)
* Default the `hostname` parameter to `$::fqdn`. This makes it easier for Marathon/Mesos/Nginx to look up other nodes, especially on a public network (although you probably shouldn't be doing that). (#24)

### Fixes
* Fix worker Dnsmasq configuration (6088bb6)

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
