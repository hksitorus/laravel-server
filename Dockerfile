FROM php:7.3.4-apache-stretch

RUN apt-get update -y
RUN apt-get install -y apt-transport-https gnupg && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update -yqq && \
    ACCEPT_EULA=Y apt-get install -y unixodbc unixodbc-dev libgss3 odbcinst msodbcsql locales && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && \
    apt-get install -y nano openssl zip unzip libzip-dev git wget libfreetype6-dev libjpeg62-turbo-dev libpng-dev libldb-dev libldap2-dev libaio-dev supervisor librabbitmq-dev libgmp-dev zlib1g-dev libicu-dev g++ libmagickwand-dev imagemagick
    

ADD oracle/instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
ADD oracle/instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
ADD oracle/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip

RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip -d /usr/local/
RUN ln -s /usr/local/instantclient_11_2 /usr/local/instantclient
RUN ln -s /usr/local/instantclient/libclntsh.so.11.1 /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/  && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/local/instantclient && \
    docker-php-ext-configure intl && \
    docker-php-ext-install -j$(nproc) gd ldap oci8 intl pdo mbstring zip pcntl bcmath soap gmp exif mysqli tokenizer

RUN pecl install -o -f redis && docker-php-ext-enable redis
RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN pecl install amqp && docker-php-ext-enable amqp
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install imagick && docker-php-ext-enable imagick
RUN pecl install sqlsrv pdo_sqlsrv && docker-php-ext-enable sqlsrv pdo_sqlsrv


RUN cd /tmp && git clone https://github.com/git-ftp/git-ftp.git && cd git-ftp \
    && tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)" \
    && git checkout "$tag" \
    && mv git-ftp /usr/local/bin && chmod +x /usr/local/bin

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/* && \
    rm -rf /var/cache/oracle-jdk8-installer



ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html
EXPOSE 80
CMD ["apache2-foreground"]