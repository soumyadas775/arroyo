# Use a slim base image for faster build
FROM ubuntu:latest
~
# Install necessary dependencies for the build process (e.g., wget, gnupg, software-properties-common)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    gnupg \
    software-properties-common \
    postgresql \                                                                                                                                          2,0-1         All
    openjdk-11-jre \
    maven \
    apache2 \
    unzip \
    apt-transport-https \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" && \
    apt-get update && \
    apt-get install -y code

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
# Copy the application index.html to Apache
COPY ./index.html /var/www/html/index.html

# Expose necessary ports
EXPOSE 80 5432

# Start Apache in the foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]
