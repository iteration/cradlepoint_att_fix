# cradlepoint_att_fix
edgerouter script to test load balancer [eth0|eth1] and fix the AT&amp;T modem if link goes down.


CBA850 Dual SIM setup.
    SIM1: AT&T << Primary
    SIM2: AT&T

Recover the AT&T connection by disabling and the reenabling SIM1.
SIM1 will drop, SIM2 will connect. SIM2 will FAILBACK after XXX seconds.


Edgerouter:

    Load Balance eth0 and eth1 using wizard
    eth0: CBA850 - AT&T
    eth1: TMobile Modem

    Copy scripts to /config/scripts

TODO: Improve script and timing to be  ore resilient
TODO: PING test on specific interface

```
set load-balance group G interface eth0 route-test count failure 1
set load-balance group G interface eth0 route-test count success 3
set load-balance group G interface eth0 route-test initial-delay 60
set load-balance group G interface eth0 route-test interval 30
set load-balance group G interface eth0 route-test type script /config/scripts/wani.sh
set load-balance group G interface eth0 weight 70
set load-balance group G interface eth1 weight 30
set load-balance group G lb-local enable
set load-balance group G lb-local-metric-change disable
```

Common commands:
```
scp wani.sh user@ip:/config/scripts/wani.sh

ssh user@ip
---
show load-balance watchdog
show load-balance status

tail -f /var/logs/messages

show configuration commands
```

