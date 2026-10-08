# Use official Maven image as build environment
FROM maven:3.9.5-eclipse-temurin-17-alpine as build

WORKDIR /workspace/app

# Copy pom.xml and source code
COPY pom.xml .
COPY src src

# Build the application
RUN mvn clean package -DskipTests

# Create the final runtime image
FROM eclipse-temurin:17-jre-alpine
VOLUME /tmp
COPY --from=build /workspace/app/target/*.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
