Documentum Operation Scripts
=============

This is a collection of administration utilities and configurations for Documentum operator.
It could be composed as a shortcut menu for many boring tasks.
Possibly like:

* monitoring health check
* performance data gathering & analyzing
* task automation

Monitor
-------

Basis scripts for monitoring:
* dctm_chk.sh: very basic health check script

you may gather data every 10 minutes with crontab
```
*/10 * * * * /opt/dctm/dba/log/dctm_chk.sh
```

OpMenu
-----------
You can compose a menu for daily operations

