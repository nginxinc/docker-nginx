#From ubuntu:latest
#test
# ENV http_proxy http://10.31.255.65:8080
# ENV https_proxy http://10.31.255.65:8080

#RUN apt update -y && apt install nginx -y 

#EXPOSE 80

#CMD ["nginx", "-g", "daemon off;"]

# Utiliser l'image de base Ubuntu
FROM ubuntu:latest

# Mettre à jour les paquets et installer Nginx
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean
RUN apt-get curl

# Copier le fichier de configuration Nginx personnalisé (si nécessaire)
# COPY nginx.conf /etc/nginx/nginx.conf

# Exposer le port 80
EXPOSE 80

# Commande pour démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]

