# Etapa 1: Construir el frontend
FROM node:14 AS build-frontend

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos de frontend y generar el build
COPY traccar-web /app/web
RUN cd web && npm install && npm run build

# Etapa 2: Construir el backend
FROM gradle:7.5.1-jdk11 AS build-backend

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar los archivos fuente y generar el JAR
COPY . /app
COPY --from=build-frontend /app/web/build /app/web/build
RUN gradle assemble

# Etapa 3: Crear la imagen final
FROM openjdk:11-jre-slim

# Establecer el directorio de trabajo
WORKDIR /opt/traccar

# Copiar el archivo JAR y el directorio de configuraciones
COPY --from=build-backend /app/target/tracker-server.jar /opt/traccar/tracker-server.jar
COPY --from=build-backend /app/target/lib /opt/traccar/lib
COPY conf /opt/traccar/conf
COPY schema /opt/traccar/schema
COPY templates /opt/traccar/templates

# Crear directorios de datos y logs
RUN mkdir -p /opt/traccar/data && mkdir -p /opt/traccar/logs

# Copiar los archivos estáticos del frontend
COPY --from=build-backend /app/web/build /opt/traccar/web

# Exponer el puerto en el que Traccar escucha
EXPOSE 8082
EXPOSE 5000-5150

# Comando para ejecutar Traccar
CMD ["java", "-jar", "/opt/traccar/tracker-server.jar", "conf/traccar.xml"]
