FROM eboraas/apache-php

MAINTAINER Giovane Japa Jr <giovanejr@gmail.com>

RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-jessie main" > /etc/apt/sources.list.d/google-cloud-sdk.list
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-jessie main" > /etc/apt/sources.list.d/gcsfuse.list

RUN apt-get -q update \
    && DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends \
    && DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends --allow-unauthenticated \
      unzip procps wget python google-cloud-sdk gcsfuse ca-certificates \
    && apt-get -q autoremove -y \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

RUN wget --no-check-certificate https://github.com/google/google-api-php-client/releases/download/v2.2.1/google-api-php-client-2.2.1.zip \
    && unzip google-api-php-client-2.2.1.zip \
    && rm google-api-php-client-2.2.1.zip

ADD google-api-php-client /google-api-php-client

RUN php -r "copy('http://getcomposer.org/installer', '/tmp/composer-setup.php');" \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && composer require google/cloud-storage

COPY Gproject-7e905bd54814.json /tmp/Gproject-7e905bd54814.json
RUN gcloud auth activate-service-account --key-file=/tmp/Gproject-7e905bd54814.json
ENV GOOGLE_APPLICATION_CREDENTIALS=/tmp/Gproject-7e905bd54814.json

RUN sed -i 's:Listen 80:Listen 8080:g' /etc/apache2/ports.conf && sed -i 's/VirtualHost *:80/VirtualHost *:8080/g' /etc/apache2/sites-enabled/000-default.conf

ADD fs /var/www/html/
RUN mkdir -p /var/www/html/files/.trash
RUN chown -R www-data:www-data /var/www/html/

RUN rm /var/www/html/index.html

COPY apache2.conf /etc/apache2/


CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

