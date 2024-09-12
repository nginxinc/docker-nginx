From ubuntu:latest
#test
# ENV http_proxy http://10.31.255.65:8080
# ENV https_proxy http://10.31.255.65:8080

RUN apt update -y && apt install nginx -y 

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]