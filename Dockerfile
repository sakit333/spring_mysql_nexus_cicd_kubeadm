################################################################################
#  Multi-Stage Dockerfile for Spring Boot Application with Nexus Deployment
#  Designed and Developed by: @sak_shetty
################################################################################

#### ---- Stage 1: Build ---- ####
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy Maven descriptor
COPY pom.xml ./
COPY settings.xml /root/.m2/settings.xml

# Download dependencies first (cached)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Inject environment vars for Nexus credentials
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG NEXUS_URL
ENV NEXUS_USERNAME=${NEXUS_USERNAME} \
    NEXUS_PASSWORD=${NEXUS_PASSWORD} \
    NEXUS_URL=${NEXUS_URL}

# Build the project
RUN mvn clean package -DskipTests -s /root/.m2/settings.xml

#### ---- Stage 2: Runtime ---- ####
FROM eclipse-temurin:17-jre-jammy AS runtime
LABEL maintainer="sak_shetty" \
      description="Spring Boot App with CI/CD Nexus Integration"

WORKDIR /app
COPY --from=build /app/target/spring_app_sak-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
