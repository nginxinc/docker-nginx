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
* modsecurity directives: https://github.com/SpiderLabs/ModSecurity-nginx
* https://www.nginx.com/blog/compiling-and-installing-modsecurity-for-open-source-nginx/
* example Docker with static module: https://github.com/theonemule/docker-waf/blob/master/waf/Dockerfile
* https://nginx.org/en/linux_packages.html#mainline
* building dynamic modules: https://www.nginx.com/blog/compiling-dynamic-modules-nginx-plus/?_ga=2.124028234.1768100344.1574456112-1181068452.1536598294

```
The njs dynamic modules for nginx have been installed.
To enable these modules, add the following to /etc/nginx/nginx.conf
and reload nginx:

    load_module modules/ngx_http_js_module.so;
    load_module modules/ngx_stream_js_module.so;

Please refer to the modules documentation for further details:
http://nginx.org/en/docs/njs/
http://nginx.org/en/docs/http/ngx_http_js_module.html
http://nginx.org/en/docs/stream/ngx_stream_js_module.html

----------------------------------------------------------------------
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Setting up nginx-module-perl (1.17.6-1~bionic) ...
----------------------------------------------------------------------

The Perl dynamic module for nginx has been installed.
To enable this module, add the following to /etc/nginx/nginx.conf
and reload nginx:

    load_module modules/ngx_http_perl_module.so;

Please refer to the module documentation for further details:
http://nginx.org/en/docs/http/ngx_http_perl_module.html

----------------------------------------------------------------------
```
