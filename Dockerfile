# syntax=docker/dockerfile:1


############################################### Release build ############################################
#
# The first image builds everything based on the git checkout of the individual projects. Following
# stages copy contents from there.

FROM gradle:7.5 AS build
LABEL stage=builder
# ARG GRADLE_TASKS="build"
ARG GRADLE_TASKS='-PmacrogenOptions=--render-timeout=60 build'

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
COPY --from=build /home/gradle/faust-gen/build/www /var/www/html
COPY apache.conf /etc/apache2/conf-available/faust.conf
RUN a2enmod rewrite negotiation proxy_http && \
  a2enconf faust && \
  mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

###################################### eXist db ####################################################

FROM existdb/existdb:latest AS exist
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
COPY --from=build /home/gradle/faust-gen/macrogen /tmp/macrogen

RUN <<EOF
/usr/bin/env
/usr/bin/apt-get update
env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3 python3-venv python3-pip python3-wheel python3-dev libgraphviz-dev build-essential
mkdir -p /opt/macrogen
cd /opt/macrogen
python3 -m venv graphviewer
. ./graphviewer/bin/activate
pip install --no-cache-dir --prefer-binary '/tmp/macrogen[production]'
EOF


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
