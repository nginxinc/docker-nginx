# TL;DR

Custom nginx build with modsecurity

## Overview

Why do we build our own nginx rather than just use a stock image?
We need the following nginx modules in an open source nginx build:

* perl
* more-headers
* modsecurity

## Resources

* modsecurity e-book on our shared Google drive: https://drive.google.com/drive/u/1/folders/1ky_9gL_stSEHupRty6EjFBefRPW4qJGj
* https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/
* https://github.com/theonemule/docker-waf/blob/master/waf/Dockerfile
* https://www.feistyduck.com/library/modsecurity%2dhandbook%2d2ed%2dfree/online/
* https://nginx.org/en/linux_packages.html#mainline
