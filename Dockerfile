ARG BUILD_IMAGE=maven:3.9.9-eclipse-temurin-17
ARG RUNTIME_IMAGE=eclipse-temurin:17-jre

FROM ${BUILD_IMAGE} AS build

WORKDIR /workspace
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./
COPY core/pom.xml core/pom.xml
COPY dao/pom.xml dao/pom.xml
COPY service/pom.xml service/pom.xml
COPY ai/pom.xml ai/pom.xml
COPY jmg/pom.xml jmg/pom.xml
COPY web/pom.xml web/pom.xml
COPY docker/maven-settings.xml /tmp/maven-settings.xml
RUN mvn -B -s /tmp/maven-settings.xml -DskipTests dependency:go-offline

COPY . .
RUN mvn -B -s /tmp/maven-settings.xml -DskipTests package

FROM ${RUNTIME_IMAGE}

ENV TZ=Asia/Shanghai \
    JAVA_OPTS="" \
    SPRING_DATASOURCE_URL=jdbc:sqlite:/app/data/data.db \
    VFSPATH=/app/data/root

WORKDIR /app/data

COPY --from=build /workspace/web/target/LeoAi-*.jar /app/LeoAi.jar
COPY root /app/root-seed
COPY docker/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh \
    && mkdir -p /app/data \
    && groupadd --system leoai \
    && useradd --system --gid leoai --home-dir /app/data leoai \
    && chown -R leoai:leoai /app

USER leoai

EXPOSE 8082
VOLUME ["/app/data"]

ENTRYPOINT ["/app/entrypoint.sh"]
