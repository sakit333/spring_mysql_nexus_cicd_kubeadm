################################################################################
#  Multi-Stage Dockerfile for Spring Boot Application with Nexus Deployment
#  Designed and Developed by: @sak_shetty
################################################################################

#### ---- Stage 1: Build & Deploy ---- ####
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
COPY settings.xml /root/.m2/settings.xml

ARG NEXUS_USER
ARG NEXUS_PASS
ENV NEXUS_USER=${NEXUS_USER} \
    NEXUS_PASS=${NEXUS_PASS}

RUN mvn clean package -DskipTests -s /root/.m2/settings.xml
# Use 'deploy' only if Nexus is reachable
# RUN mvn clean package -DskipTests deploy -Dnexus.username=$NEXUS_USER -Dnexus.password=$NEXUS_PASS -s /root/.m2/settings.xml

#### ---- Stage 2: Runtime ---- ####
FROM eclipse-temurin:17-jre-jammy AS runtime
LABEL maintainer="sak_shetty" \
      description="Spring Boot App built and designed by sak_shetty"

WORKDIR /app
COPY --from=build /app/target/spring_app_sak-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
