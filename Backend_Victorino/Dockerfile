# =====================================================================
# Dockerfile multi-etapa del backend Spring Boot.
#
# Pensado para usarse SOLO en el flujo "docker-compose local" que
# distribuye el codigo del TFG al tribunal y a companeros. En el
# despliegue de produccion (Railway) NO se usa este Dockerfile: alli
# Railway usa Nixpacks para compilar directamente desde el pom.xml.
#
# Construir manualmente (sin compose):
#   docker build -t victorino-backend ./Backend_Victorino
#   docker run -p 8080:8080 --env-file .env victorino-backend
# =====================================================================

# ---------------------------------------------------------------------
# Etapa 1: builder con JDK + Maven completos.
# ---------------------------------------------------------------------
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copia primero solo el pom.xml para aprovechar la cache de Docker:
# mientras no cambien las dependencias, no se vuelven a descargar.
COPY pom.xml .
COPY .mvn ./.mvn
COPY mvnw mvnw.cmd ./
# En Windows el bit de ejecucion no se preserva al hacer commit, asi que
# lo forzamos aqui para que el script funcione dentro del contenedor Linux.
RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

# Ahora si copiamos el codigo fuente y empaquetamos.
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# El JAR resultante queda en target/Backend_Victorino-0.0.1-SNAPSHOT.jar
# Lo renombramos a un nombre fijo para que la etapa 2 no dependa de la version.
RUN mv target/Backend_Victorino-*.jar target/app.jar

# ---------------------------------------------------------------------
# Etapa 2: runtime ligero con solo JRE.
# ---------------------------------------------------------------------
# eclipse-temurin:21-jre-alpine pesa ~80 MB vs ~600 MB del jdk completo.
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Usuario no-root por buenas practicas de seguridad.
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

COPY --from=build /app/target/app.jar /app/app.jar

# El backend respeta server.port=${PORT:8080} de application.properties.
EXPOSE 8080

# JAVA_TOOL_OPTIONS limita la memoria del JVM (mismo valor que en Railway).
ENV JAVA_TOOL_OPTIONS="-Xmx400m -Xms256m -XX:+UseSerialGC -XX:MaxMetaspaceSize=128m"

CMD ["java", "-jar", "/app/app.jar"]
