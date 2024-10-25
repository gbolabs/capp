FROM --platform=amd64 nginx:1.21
RUN rm -rf /usr/share/nginx/html/*

# Copy the custom Nginx configuration
COPY ./nginx.conf.template /

# Copy the runner.sh script
COPY ./runner.sh /
RUN chmod +x /runner.sh & mv /runner.sh /docker-entrypoint.d/09-runner.sh