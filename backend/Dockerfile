# =====================
# Build stage
# =====================
FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /app

# copy maven wrapper
COPY .mvn .mvn
COPY mvnw .
COPY pom.xml .

# 🔑 FIX: add execute permission
RUN chmod +x mvnw

# download dependencies
RUN ./mvnw -B dependency:go-offline

# copy source & build
COPY src src
RUN ./mvnw -B package -DskipTests

# =====================
# Runtime stage
# =====================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# copy jar
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 30000

# Actuator healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:30000/actuator/health || exit 1

ENTRYPOINT ["java","-jar","app.jar"]
