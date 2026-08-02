# Base Image
FROM tomcat:10.1-jdk21-temurin

# Metadata
LABEL maintainer="Rajesh Tutta"
LABEL application="train-ticket-booking"
LABEL version="1.0"

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

# Create non-root user
RUN groupadd -r appgroup && \
    useradd -r -g appgroup appuser && \
    chown -R appuser:appgroup /usr/local/tomcat

USER appuser

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]