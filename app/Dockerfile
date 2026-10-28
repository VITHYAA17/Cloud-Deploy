# Build stage
FROM maven:3.9.5-eclipse-temurin-17-alpine AS build

WORKDIR /workspace/app

COPY pom.xml .
COPY src src

RUN mvn clean package -DskipTests

# Secure Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Create unprivileged application user and group for container security compliance
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
VOLUME /tmp

COPY --from=build --chown=appuser:appgroup /workspace/app/target/*.jar app.jar

# Switch to non-root user
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
