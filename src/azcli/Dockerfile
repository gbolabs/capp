FROM ubuntu:20.04

# Install the Azure CLI
RUN apt-get update && apt-get install -y curl && \
	curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
	rm -rf /var/lib/apt/lists/*

# Copy the script to the container
COPY ./runner.sh /runner.sh

# Change CRLF to LF and change the script permissions
RUN sed -i 's/\r$//' /runner.sh && chmod +x /runner.sh

# Entrypoint
ENTRYPOINT ["/runner.sh"]