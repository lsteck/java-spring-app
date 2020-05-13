# IBM Java SDK UBI is not available on public docker yet. Use regular
# base as builder until this is ready. For reference:
# https://github.com/ibmruntimes/ci.docker/tree/master/ibmjava/8/sdk/ubi-min

# FROM ibmjava:8-sdk AS builder
# FROM openjdk:8 AS builder
FROM maven:3.6.3-jdk-8 AS builder
LABEL maintainer="IBM Java Engineering at IBM Cloud"

WORKDIR /app
# fix permissions error.
# USER root
# RUN chgrp -R 0 /usr/share && \
#     chmod -R g+rwX /usr/share && \
#     chown -R 100:0 /usr/share
# RUN apt-get update && apt-get install -y maven

COPY pom.xml .
# https://github.com/aws/aws-codebuild-docker-images/issues/237
# ENV MAVEN_CONFIG '' 
# This broke the Tag release step in build number 17
# See https://issues.jenkins-ci.org/browse/JENKINS-47890
# put unset MAVEN_CONFIG in script
# Still borke it
# RUN mvn -N io.takari:maven:wrapper -Dmaven=3.5.0

COPY . /app
# ENV M2_HOME /usr/share/maven
# ENV M3_HOME /usr/share/maven
# ENV PATH /usr/share/maven/bin:$PATH
# RUN ls /usr/share/maven
# RUN printenv
# RUN ./mvnw install
# RUN java -version
# RUN mvn -version
RUN mvn install

ARG bx_dev_user=root
ARG bx_dev_userid=1000
RUN BX_DEV_USER=$bx_dev_user
RUN BX_DEV_USERID=$bx_dev_userid
RUN if [ $bx_dev_user != "root" ]; then useradd -ms /bin/bash -u $bx_dev_userid $bx_dev_user; fi

# Multi-stage build. New build stage that uses the UBI as the base image.

# In the short term, we are using the OpenJDK for UBI. Long term, we will use
# the IBM Java Small Footprint JVM (SFJ) for UBI, but that is not in public
# Docker at the moment.
# (https://github.com/ibmruntimes/ci.docker/tree/master/ibmjava/8/sfj/ubi-min)

FROM adoptopenjdk/openjdk8:ubi-jre

# Copy over app from builder image into the runtime image.
RUN mkdir /opt/app
COPY --from=builder /app/target/javaspringapp-1.0-SNAPSHOT.jar /opt/app/app.jar

ENTRYPOINT [ "sh", "-c", "java -jar /opt/app/app.jar" ]
