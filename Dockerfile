################################################################################
#  🚀 Multi-Stage Dockerfile — Spring Boot + Maven + Nexus CI/CD
#  Designed by: @sak_shetty
################################################################################

#### ---- Stage 1: Build ---- ####
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy project configuration
COPY pom.xml .
COPY settings.xml /root/.m2/settings.xml

# Fetch dependencies first (cache optimization)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build arguments and environment for Nexus
ARG NEXUS_USER=admin
ARG NEXUS_PASS=admin
ENV NEXUS_USER=${NEXUS_USER} \
    NEXUS_PASS=${NEXUS_PASS}

# Build and (optional) deploy
RUN mvn clean package -DskipTests -s /root/.m2/settings.xml
# To enable Nexus deploy:
# RUN mvn clean deploy -DskipTests -s /root/.m2/settings.xml

#### ---- Stage 2: Runtime ---- ####
FROM eclipse-temurin:17-jre-jammy AS runtime
LABEL maintainer="sak_shetty" \
      description="Spring Boot App built and designed by @sak_shetty"

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8085

ENTRYPOINT ["java", "-jar", "app.jar"]
