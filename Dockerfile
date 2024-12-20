# syntax=docker/dockerfile:1


############################################### Release build ############################################
#
# The first image builds everything based on the git checkout of the individual projects. Following
# stages copy contents from there.


FROM gradle:7.5 AS build
LABEL stage=builder
# ARG GRADLE_TASKS="build"
ARG MACROGEN_RENDER_TIMEOUT=""
ARG GRADLE_TASKS="-PmacrogenOptions=--render-timeout=$MACROGEN_RENDER_TIMEOUT --no-daemon --console plain build"

# All following dependencies are required for chromium which renders the SVGs:
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  fonts-uralic \
  libalut0 \
  libc6 \
  libgcc-s1 \
  libgl1 \
  libglc0 \
  libglu1-mesa \
  libglu1 \
  libopenal1 \
  libsdl2-2.0-0 \
  libsdl2-image-2.0-0 \
  libstdc++6 \
  libxdamage1 \
  libxtst6 \
  libglib2.0-0 \
  libnss3 \
  libcups2 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libpangocairo-1.0-0 \
  libgtk-3-0 \
  libxcomposite1
COPY --chown=gradle:gradle workflow/ /home/gradle/faust-gen
COPY --chown=gradle:gradle init.gradle.kts /home/gradle/.gradle/init.gradle.kts

WORKDIR /home/gradle/faust-gen
USER gradle
# ARG CACHEBUST=0
RUN gradle ${GRADLE_TASKS} --no-daemon --continue


###################################### Main web frontend ##########################################
#
# Website and apache serving everything.

FROM php:8-apache AS www
LABEL stage=www
LABEL org.containers.image.authors="Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
LABEL org.opencontainers.image.url="https://faustedition.net/"
LABEL org.opencontainers.image.source="https://github.com/faustedition/faust-gen-docker"
LABEL org.opencontainers.image.title="Faustedition Web-Frontend"

COPY --from=build /home/gradle/faust-gen/build/www /var/www/html
COPY apache.conf /etc/apache2/conf-available/faust.conf
RUN a2enmod rewrite negotiation proxy_http alias && \
  a2enconf faust && \
  mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
VOLUME /facsimile

#################################### Previous version of the website ################################
FROM php:8-apache AS www-old
ARG WWW
COPY $WWW /var/www/html
COPY apache.conf /etc/apache2/conf-available/faust.conf
RUN a2enmod rewrite negotiation proxy_http alias && \
  a2enconf faust && \
  mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
VOLUME /facsimile

###################################### eXist db ####################################################

FROM existdb/existdb:latest AS exist
LABEL org.containers.image.authors="Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
LABEL org.opencontainers.image.url="https://faustedition.net/"
LABEL org.opencontainers.image.source="https://github.com/faustedition/faust-gen-docker"
LABEL org.opencontainers.image.title="Faustedition eXist Database"
# ARG VERSION=6.2
# ENV EXIST_ENV=production
# ENV EXIST_DEFAULT_APP_PATH=xmldb:exist:///db/apps/faust-dev
# USER wegajetty
# ADD --chown=wegajetty:wegajetty http://exist-db.org/exist/apps/public-repo/public/shared-resources-0.9.1.xar ${EXIST_HOME}/autodeploy/
# COPY --from=build --chown=wegajetty:wegajetty /home/gradle/faust-gen/build/faust-dev.xar ${EXIST_HOME}/autodeploy/
ADD http://exist-db.org/exist/apps/public-repo/public/shared-resources-0.9.1.xar /exist/autodeploy/
COPY --from=build /home/gradle/faust-gen/build/faust-dev.xar /exist/autodeploy/


####################################### Macrogenesis server ########################################
FROM python:3.11-slim AS macrogen-build
LABEL org.containers.image.authors="Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
LABEL org.opencontainers.image.url="https://faustedition.net/"
LABEL org.opencontainers.image.source="https://github.com/faustedition/faust-gen-docker"
LABEL org.opencontainers.image.title="Faustedition Macrogenesis Subgraph Service"
COPY --from=build /home/gradle/faust-gen/macrogen /tmp/macrogen
COPY macrogen /opt/macrogen
COPY download-server /tmp/download-server

RUN <<EOF
/usr/bin/env
/usr/bin/apt-get update
env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 python3-venv python3-pip python3-wheel python3-dev libgraphviz-dev build-essential
mkdir -p /opt/macrogen
cd /opt/macrogen
python3 -m venv graphviewer
chmod 755 ./graphviewer/bin/activate
. ./graphviewer/bin/activate
pip install --no-cache-dir --prefer-binary -r requirements.txt
deactivate

mkdir -p /opt/downloads 
cd /opt/downloads
python3 -m venv downloadserver
. ./downloadserver/bin/activate 
pip install --no-cache-dir --prefer-binary '/tmp/download-server[production]'
EOF

## The actual server image

# FROM alpine:3.19 AS macrogen
FROM python:3.11-slim AS macrogen
RUN adduser --system --home /opt/macrogen macrogen
# RUN apk add --no-cache graphviz python3 && \
# RUN   adduser -h /opt/macrogen -S -D macrogen
COPY macrogen /opt/macrogen
COPY --from=build /home/gradle/faust-gen/build/www/macrogenesis/macrogen-info.zip /opt/macrogen/
COPY --from=build /home/gradle/faust-gen/src/main/xproc/xslt/bibliography.xml /opt/macrogen/
COPY --from=macrogen-build /opt/macrogen/graphviewer /opt/macrogen/graphviewer

RUN <<EOF
apt-get update
env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends graphviz
EOF

USER macrogen
WORKDIR /opt/macrogen
CMD [ "/opt/macrogen/entrypoint.sh" ]

################ facsimile download server #######################

FROM python:3.11-slim AS downloadserver
LABEL org.containers.image.authors="Thorsten Vitt <thorsten.vitt@uni-wuerzburg.de>, Faustedition <info@faustedition.net>"
LABEL org.opencontainers.image.url="https://faustedition.net/"
LABEL org.opencontainers.image.source="https://github.com/faustedition/faust-gen-docker"
LABEL org.opencontainers.image.title="Faustedition Facsimile Download Server"
RUN adduser --system --home /opt/downloads downloads
COPY downloadserver /opt/downloads
COPY --from=macrogen-build /opt/downloads/downloadserver /opt/downloads/downloadserver

VOLUME /facsimile
USER downloads
WORKDIR /opt/downloads
CMD [ "/opt/downloads/entrypoint.sh" ]
