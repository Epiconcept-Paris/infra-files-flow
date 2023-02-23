# StartLimit errors with indirdwake

## Discovery
Early 2023, thanks to the deployment of `grafana`, repeated messages like  
`<date> <system>systemd[1]: indirdwake@SSP_POiTIERS_ADT.service: Failed with result 'start-limit-hit'.`  
were noticed in `/var/log/daemon.log` on a Debian 9 system running many instances of `indird`.

## Fix
It was quickly determined that the messages needed the use of a `SmartLimitInterval*` systemd setting.  
First, a `StartLimitIntervalSec=0` setting was put in `indirdwake@.path`. It was recognized (no error) but it had no visible effect.  
Second, this setting was moved to indirdwake@.service where `systemd-analyze verify indirdwake@.service` immediately detected it as invalid.  
Third, further research led to the discovery of a `SmartLimitInterval=` setting on the different systemd releases of Debian versions 9,10,11. Tests on version 232 of systemd on Debian 9 showed that this setting was not only recognized in `indirdwake@.service`, but also **worked** as expected.

## Check for `SmartLimitInterval` in systemd's source code
A quick search was then done on the sources of the different versions of systemd:

| systemd version | Debian version |
---
| systemd-232-25+deb9u15 | 9.13 |
| systemd-241-7~deb10u8 | 10.13 |
| systemd-247.3-7+deb11u1 | 11.6 |

The fetch, untar and grep process was consigned in the `getsrc` script.
As the `work/grep.out` file points out to, a post-232 comment has been added to version 229's NEWS in `work/systemd-241/NEWS` and `work/systemd-stable-247.3/NEWS` that seems to announce that the `SmartLimitInterval=` setting will still work on Debian 10 and 11:
```
        * The settings StartLimitBurst=, StartLimitInterval=, StartLimitAction=
          and RebootArgument= have been moved from the [Service] section of
          unit files to [Unit], and they are now supported on all unit types,
          not just service units. Of course, systemd will continue to
          understand these settings also at the old location, in order to
          maintain compatibility.
```
2023-02-23
