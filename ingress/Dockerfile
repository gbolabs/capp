FROM --platform=amd64 nginx:1.21

# Remove the default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy the custom Nginx configuration
COPY ./nginx.conf /etc/nginx/nginx.conf

