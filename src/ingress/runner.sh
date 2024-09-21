#!/bin/bash

# Define the path to the template file
TEMPLATE_FILE="/nginx.conf.template"

# Define the path to the output file
OUTPUT_FILE="/etc/nginx/nginx.conf"

# Read the template file and replace placeholders with environment variables
sed -e 's/__CAPP_API_HOST__/'"$CAPP_API_HOST"'/g' \
    -e 's/__CAPP_API_PORT__/'"$CAPP_API_PORT"'/g' \
    -e 's/__CAPP_API_SCHEME__/'"$CAPP_API_SCHEME"'/g' \
    -e 's/__CAPP_WEB_HOST__/'"$CAPP_WEB_HOST"'/g' \
    -e 's/__CAPP_WEB_PORT__/'"$CAPP_WEB_PORT"'/g' \
    -e 's/__CAPP_WEB_SCHEME__/'"$CAPP_WEB_SCHEME"'/g' \
    -e 's/__CAPP_CARBONE_HOST__/'"$CAPP_CARBONE_HOST"'/g' \
    -e 's/__CAPP_CARBONE_PORT__/'"$CAPP_CARBONE_PORT"'/g' \
    -e 's/__CAPP_CARBONE_SCHEME__/'"$CAPP_CARBONE_SCHEME"'/g' \
    /nginx.conf.template > /etc/nginx/nginx.conf

# If ENV_VAR Debug is present, print the content of the output file
if [ -n "$DEBUG" ]; then
    cat "$OUTPUT_FILE"
fi

echo "nginx configuration has been generated at $OUTPUT_FILE"

# run the nginx server
nginx -g "daemon off;"