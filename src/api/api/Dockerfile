# Stage 1: Build the .NET API
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the project file and restore dependencies
COPY api/*.csproj ./api/
COPY Infrastructure/*.csproj ./Infrastructure/
COPY api.sln .

# Avoid dotnet restore to run indefinitely
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV DOTNET_EnableWriteXorExecute=0

RUN dotnet restore api.sln

# Copy the rest of the source code and build the API
COPY . .

RUN dotnet publish -c Release -o out --no-build --no-restore ./api/api.csproj

# Stage 2: Run the .NET API
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/out .

# Expose the port and start the API
ENV ASPNETCORE_PORT=80
EXPOSE 80
ENTRYPOINT ["dotnet", "api.dll"]