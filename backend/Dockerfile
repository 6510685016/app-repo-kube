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

# 🔑 FIX: ติดตั้ง curl เพื่อให้ HEALTHCHECK ทำงานได้
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8765

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8765/actuator/health || exit 1

ENTRYPOINT ["java","-jar","app.jar"]