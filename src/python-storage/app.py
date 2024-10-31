import os
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

# Set up the necessary variables
account_url = os.getenv("AZURE_STORAGE_ACCOUNT_URL")
container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME")
azure_client_id = os.getenv("AZURE_CLIENT_ID")
auth_type = os.getenv("AZURE_AUTH_TYPE")

if not azure_client_id:
    azure_client_id = "ManagedIdentity"

if auth_type not in ["ManagedIdentity", "Default"]:
    raise ValueError("AZURE_AUTH_TYPE must be 'ManagedIdentity' or 'Default'. Received: {auth_type}")

if not account_url:
    raise ValueError("AZURE_STORAGE_ACCOUNT_URL is not set.")
if not container_name:
    raise ValueError("AZURE_STORAGE_CONTAINER_NAME is not set.")

directory_name = "my-directory"
file_name = "my-file.txt"
file_content = "Hello, Azure Blob Storage!"

# Authenticate using DefaultAzureCredential (Managed Identity)
if auth_type == "ManagedIdentity":
    credential = ManagedIdentityCredential(client_id=azure_client_id)
else:
    credential = DefaultAzureCredential()

# fetch the storage account hostname
storagehost = account_url.replace("https://", "").replace("/", "")

# try DNS resolution to verify the hostname
try:
    import socket
    host = socket.gethostbyname(storagehost)
    print(f"Resolved hostname '{storagehost}' to IP '{host}'")
except:
    raise ValueError(f"Unable to resolve the hostname '{storagehost}'")

# Create the BlobServiceClient object
blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)

# Create a container
container_client = blob_service_client.create_container(container_name)

# Create a directory (Azure Blob Storage does not have a directory structure, so we simulate it using a blob with a directory prefix)
directory_blob_client = container_client.get_blob_client(f"{directory_name}/")

# Create a file in the directory
file_blob_client = container_client.get_blob_client(f"{directory_name}/{file_name}")
file_blob_client.upload_blob(file_content)

print(f"Container '{container_name}' created.")
print(f"Directory '{directory_name}' simulated.")
print(f"File '{file_name}' created with content: '{file_content}'")