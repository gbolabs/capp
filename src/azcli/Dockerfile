FROM --platform=amd64 mcr.microsoft.com/azure-cli:cbl-mariner2.0

# Copy the script to the container
COPY ./runner.sh /runner.sh

# Change CRLF to LF and change the script permissions
RUN sed -i 's/\r$//' /runner.sh && chmod +x /runner.sh

# Entrypoint
ENTRYPOINT ["/runner.sh"]