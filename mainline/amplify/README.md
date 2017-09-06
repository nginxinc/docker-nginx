<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [1. Overview](#1-overview)
  - [1.1. NGINX Amplify Agent Inside Docker Container](#11-nginx-amplify-agent-inside-docker-container)
  - [1.2. Standalone Mode](#12-standalone-mode)
  - [1.3. Aggregate Mode](#13-aggregate-mode)
  - [1.4. Current Limitations](#14-current-limitations)
- [2. How to Build and Run an Amplify-enabled NGINX image?](#2-how-to-build-and-run-an-amplify-enabled-nginx-image)
  - [2.1. Building an Amplify-enabled image with NGINX](#21-building-an-amplify-enabled-image-with-nginx)
  - [2.2. Running an Amplify-enabled NGINX Docker Container](#22-running-an-amplify-enabled-nginx-docker-container)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## 1. Overview

[NGINX Amplify](https://amplify.nginx.com/signup/) is a free monitoring tool that can be used with a microservice architecture based on NGINX and Docker. Amplify is developed and maintained by Nginx Inc. — the company behind the NGINX software.

With Amplify it is possible to collect and aggregate metrics across Docker containers, and present a coherent set of visualizations of the key NGINX performance data, such as active connections or requests per second. It is also easy to quickly check for any performance degradations, traffic anomalies, and get a deeper insight into the NGINX configuration in general.

In order to use Amplify, a small Python-based agent software [Amplify Agent](https://github.com/nginxinc/nginx-amplify-agent) should be installed inside the container.

The official documentation for Amplify is available [here](https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md).

### 1.1. NGINX Amplify Agent Inside Docker Container 

The Amplify Agent can be deployed in a Docker environment to monitor NGINX instances inside Docker containers.

The "agent-inside-the-container" is currenly the only mode of operation. In other words, the agent should be running in the same container, next to the NGINX instance.

### 1.2. Standalone Mode

By default the agent will try to determine the OS `hostname` on startup (see the docs [here](https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md#changing-the-hostname-and-uuid) for more information). The `hostname` is used to generate an UUID to uniquely identify the new object in the monitoring backend.

This means that in the absence of the additional configuration steps, each new container started from an Amplify-enabled Docker image will be reported as a standalone system in the Amplify web user interface. Moreover, the reported hostname is typically something not easily readable.

When using Amplify with Docker, another option is available and recommended — which is `imagename`. The `imagename` option tells the Amplify Agent that it's running in a container environment, and that the agent should collect and report metrics and metadata accordingly.

If you prefer to see the individual instances started from the same image as separate objects, assign different `imagename` to each of the running instances.

You can learn more about the agent configuration options [here](https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md#configuring-the-agent).

### 1.3. Aggregate Mode

As described above, when reporting a new object for monitoring, the agent honors the `imagename` configuration option in the **/etc/amplify-agent/agent.conf** file.

The `imagename` option should be set either in the Dockerfile or using the environment variables.

It is possible to explicitly specify the same `imagename` for multiple instances. In this scenario, the metrics received from several agents will be aggregated internally on the backend side — with a single 'container'-type object created for monitoring.

This way a combined view of various statistics can be obtained (e.g. for a "microservice"). For example, this combined view can display the total number of requests per second through all backend instances of a microservice.

Containers with a common `imagename` do not have to share the same local Docker image or NGINX configuration. They can be located on different physical hosts too.

To set a common `imagename` for several containers started from the Amplify-enabled image, you may either:

  * Configure it explicitly in the Dockerfile
  
  ```
  # If AMPLIFY_IMAGENAME is set, the startup wrapper script will use it to
  # generate the 'imagename' to put in the /etc/amplify-agent/agent.conf
  # If several instances use the same 'imagename', the metrics will
  # be aggregated into a single object in NGINX Amplify. Otherwise Amplify
  # will create separate objects for monitoring (an object per instance).
  # AMPLIFY_IMAGENAME can also be passed to the instance at runtime as
  # described below.
  
  ENV AMPLIFY_IMAGENAME my-docker-instance-123
  ```

  or

  * Use the `-e` option with `docker run` as in

  ```
  docker run --name mynginx1 -e API_KEY=ffeedd0102030405060708 -e AMPLIFY_IMAGENAME=my-service-123 -d nginx-amplify
  ```

### 1.4. Current Limitations 

The following list summarizes existing limitations of monitoring Docker containers with Amplify:

 * In order for the agent to collect [additional NGINX metrics](https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md#additional-nginx-metrics) the NGINX logs should be kept inside the container (by default the NGINX logs are redirected to the Docker log collector). Alternatively the NGINX logs can be fed to the agent via [syslog](https://github.com/nginxinc/nginx-amplify-doc/blob/master/amplify-guide.md#configuring-syslog).
 * In "aggregate" mode, some of the OS metrics and metadata are not collected (e.g. hostnames, CPU usage, Disk I/O metrics, network interface configuration).
 * The agent can only monitor NGINX from inside the container. It is not currently possible to run the agent in a separate container and monitor the neighboring containers running NGINX.
 
We've been working on improving the support for Docker even more. Stay tuned!

## 2. How to Build and Run an Amplify-enabled NGINX image?

### 2.1. Building an Amplify-enabled image with NGINX

(**Note**: If you are really new to Docker, [here's](https://docs.docker.com/engine/installation/) how to install Docker Engine on various OS.)

Let's pick our official [NGINX Docker image](https://hub.docker.com/_/nginx/) as a good example. The Dockerfile that we're going to use for an Amplify-enabled image is [part of this repo](https://github.com/nginxinc/docker-nginx-amplify/blob/master/Dockerfile).

Here's how you can build the Docker image with the Amplify Agent inside, based on the official NGINX image:

```
git clone https://github.com/nginxinc/docker-nginx-amplify.git
```

```
cd docker-nginx-amplify
```

```
docker build -t nginx-amplify .
```

After the image is built, check the list of Docker images:

```
docker images
```

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx-amplify       latest              d039b39d2987        3 minutes ago       241.6 MB
```

### 2.2. Running an Amplify-enabled NGINX Docker Container

Unless already done, you have to [sign up](https://amplify.nginx.com/signup/), create an account in NGINX Amplify, and obtain a valid API_KEY.

To start a container from the new image, use the command below:

```
docker run --name mynginx1 -e API_KEY=ffeedd0102030405060708 -e AMPLIFY_IMAGENAME=my-service-123 -d nginx-amplify
```

where the API_KEY is that assigned to your NGINX Amplify account, and the AMPLIFY_IMAGENAME is set to identify the running service as described in sections 1.2 and 1.3 above.

After the container has started, you may check its status with `docker ps`:

```
docker ps
```

```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
7d7b47ba4c72        nginx-amplify       "/entrypoint.sh"    3 seconds ago       Up 2 seconds        80/tcp, 443/tcp     mynginx1
```

and you can also check `docker logs`:

```
docker logs 7d7b47ba4c72
```

```
starting nginx ...
updating /etc/amplify-agent/agent.conf ...
---> using api_key = ffeedd0102030405060708
---> using imagename = my-service-123
starting amplify-agent ...
```

Check what processes have started:

```
docker exec 7d7b47ba4c72 ps axu
```

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1   4328   676 ?        Ss   19:33   0:00 /bin/sh /entrypoint.sh
root         5  0.0  0.5  31596  2832 ?        S    19:33   0:00 nginx: master process nginx -g daemon off;
nginx       11  0.0  0.3  31988  1968 ?        S    19:33   0:00 nginx: worker process
nginx       65  0.6  9.1 111584 45884 ?        S    19:33   0:06 amplify-agent
```

If you see the **amplify-agent** process, it all went smoothly, and you should see the new container in the Amplify web user interface in about a minute or so.

Check the Amplify Agent log:

```
docker exec 7d7b47ba4c72 tail /var/log/amplify-agent/agent.log
```

```
2016-08-05 19:49:39,001 [65] supervisor agent started, version=0.37-1 pid=65 uuid=<..> imagename=my-service-123
2016-08-05 19:49:39,047 [65] nginx_config running nginx -t -c /etc/nginx/nginx.conf
2016-08-05 19:49:40,047 [65] supervisor post https://receiver.amplify.nginx.com:443/<..>/ffeedd0102030405060708/agent/ 200 85 4 0.096
2016-08-05 19:50:24,674 [65] bridge_manager post https://receiver.amplify.nginx.com:443/<..>/ffeedd0102030405060708/update/ 202 2370 0 0.084
```

When you're done with the container, you can stop it like the following:

```
docker stop 7d7b47ba4c72
```

To check the status of all containers (running and stopped):

```
docker ps -a
```

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
7d7b47ba4c72        nginx-amplify       "/entrypoint.sh"         22 minutes ago      Exited (137) 19 seconds ago                       mynginx1
```

Happy monitoring, and feel free to send us questions, opinions, and any feedback in general.
