# Stage 1: Build the Node.js app
FROM --platform=amd64 node:22 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Create the Nginx image and expose the app's content
FROM --platform=amd64 nginx:1
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist/btweb/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]