################################################################################
# Multi-Stage Dockerfile for Spring Boot Application
# Designed by @sak_shetty
#
# Supports 2 modes:
#  - dev: build JAR only
#  - prod: build & deploy to Nexus
################################################################################

#### ---- Stage 1: Build ---- ####
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
COPY settings.xml /root/.m2/settings.xml

# Build-time arguments for environment selection
ARG BUILD_ENV=dev
ARG NEXUS_USER
ARG NEXUS_PASS

ENV NEXUS_USER=${NEXUS_USER} \
    NEXUS_PASS=${NEXUS_PASS}

# Conditionally deploy only in prod
RUN if [ "$BUILD_ENV" = "prod" ]; then \
      mvn clean package deploy -DskipTests \
        -Dnexus.username=$NEXUS_USER \
        -Dnexus.password=$NEXUS_PASS \
        -s /root/.m2/settings.xml; \
    else \
      mvn clean package -DskipTests; \
    fi

#### ---- Stage 2: Runtime ---- ####
FROM openjdk:17-jdk-slim AS runtime
LABEL maintainer="sak_shetty"
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
