# Use the base Ubuntu image
FROM ubuntu:20.04

# Install dependency packages
RUN apt update && apt install -y wget jq zip ftp mysql-client

# Copy the shell script file to the container
COPY migrate_website.sh /

# Copy the unzipper.php file to the container
COPY unzipper.php /

# Copy the JSON files to the container
COPY *.json /

# Run migrate_website.sh with /bin/bash
CMD ["/bin/bash", "migrate_website.sh"]