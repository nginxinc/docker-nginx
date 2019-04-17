# About this Repo

This is a fork of the Git repo of the official Docker image for [nginx](https://registry.hub.docker.com/_/nginx/)
(who knows better how to build nginx??). See the Hub page for the full readme on how to use the Docker image
and for information regarding contributing and issues.

We (ProdataKey), just need it to compile nginx with native modules we need. We plan to maintain this in step with mainline.

Ultimate goal would be to make adding a native code module to docker-nginx simply configurable and commit upstream.
Adding native modules is pretty painful right now:

- add OS deps
- pull code
- modify nginx configure `--add-module /usr/src/modulepath`.
- modify nginx.conf


This must currently be done in each of the 8 individual $os/$os-perl branches of the repo (or just the one you use! mainline alpine here). 

Currently Added Modules:

- [nginx-vts](https://github.com/vozlt/nginx-module-vts)


The full readme is generated over in [docker-library/docs](https://github.com/docker-library/docs),
specificially in [docker-library/docs/nginx](https://github.com/docker-library/docs/tree/master/nginx).

