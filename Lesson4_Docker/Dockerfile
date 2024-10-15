FROM nginx:latest
RUN echo 'deb http://mirror.hoster.kz/debian/ bookworm main non free' > /etc/apt/sources.list.d/backports.list
RUN apt update -y && apt upgrade -y
RUN apt install nginx && apt-get clean
RUN rm -rf /var/www/
RUN mkdir -p /var/www/test.company.com/img
COPY index.html /var/www/test.company.com/
COPY image.png /var/www/test.company.com/img/
RUN chmod 754 -R /var/www/test.company.com
RUN useradd kirill 
RUN groupadd kirillGroup
RUN usermod -a -G kirillGroup kirill
RUN chown kirill:kirillGroup -R /var/www/test.company.com
RUN sed -i 's|/usr/share/nginx/html|/var/www/test.company.com|g' /etc/nginx/conf.d/default.conf 
RUN sed -i 's|nginx;|kirill;|g' /etc/nginx/nginx.conf
