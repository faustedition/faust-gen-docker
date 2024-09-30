FROM gradle:7.5-alpine AS build
ARG GRADLE_TASKS="clean build"
COPY --chown=gradle:gradle . /home/gradle/faust-gen
COPY --chown=gradle:gradle init.gradle.kts /home/gradle/.gradle/init.gradle.kts
WORKDIR /home/gradle/faust-gen
USER gradle
RUN gradle ${GRADLE_TASKS} --no-daemon --info --continue 

FROM php:8-apache AS www
COPY --from=build /home/gradle/src/build/www /var/www/html
