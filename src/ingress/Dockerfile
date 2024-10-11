FROM --platform=amd64 nginx:1
RUN rm -rf /usr/share/nginx/html/*

# Copy the custom Nginx configuration
COPY ./nginx.conf.template /

# Copy the runner.sh script
COPY ./runner.sh /
RUN chmod +x /runner.sh

# Set the custom entrypoint
ENTRYPOINT ["/runner.sh"]