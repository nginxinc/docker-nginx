# TL;DR

Helpers for running CIS nginx benchmark (security scan) against a prod-like nginx configuration.

## CIS Cat Pro Assessor

The [CIS Cat Pro](https://www.cisecurity.org/cybersecurity-tools/cis-cat-pro/) assessor tool is available from CIS Security's web site.  University of Chicago is a CIS member, so the tool
is available if you login with a @uchicago.edu e-mail.
See https://workbench.cisecurity.org/

## Problems

Unfortunately I was unable to get the assessor to run within
a Docker container.  I finally just installed our revproxy
nginx configuration (harvested with `test/cis/runTest.sh`) on
my local laptop, and ran the assessment there.

The in-container error is as follows:
```
$ sudo bash ./Assessor-CLI.sh -vvvvv -b benchmarks/CIS_NGINX_Benchmark_v1.1.0-xccdf.xml
...
Verifying application

Obtaining session connection --> Local
Connection established.
An error occurred creating the session for null@null:0.  Ensure all session configuration information is correct.

Unable to connect session configuration --> null@null:0
```
