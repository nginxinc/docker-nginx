#/sh

docker run -d  -v //c/Users/movie:/usr/share/nginx/html/movie -p 8080:80 --name docker-nginx docker-nginx:20170617

exit 0

