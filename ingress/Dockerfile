FROM --platform=amd64 nginx:1.21


# RUN ln -sf /dev/stdout /var/log/nginx/access.log \
#     && ln -sf /dev/stderr /var/log/nginx/error.log \
#     &&  rm -rf /usr/share/nginx/html/*

RUN rm -rf /usr/share/nginx/html/*

# Copy the custom Nginx configuration
COPY ./nginx.conf /etc/nginx/nginx.conf

