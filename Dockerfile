FROM ubuntu:latest

# ENV http_proxy http://10.31.255.65:8080
# ENV https_proxy http://10.31.255.65:8080
# Mettre à jour les paquets et installer Nginx

RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean
#RUN apt-get install curl

# Copier le fichier de configuration Nginx personnalisé (si nécessaire)
# COPY nginx.conf /etc/nginx/nginx.conf

# Exposer le port 80
EXPOSE 80

# Commande pour démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
