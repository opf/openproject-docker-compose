FROM node:18 AS build

WORKDIR /app

# Clone the repository
RUN git clone https://github.com/excalidraw/excalidraw.git .

# Install dependencies
RUN npm install

# Build with custom base path
ENV VITE_APP_BASE_PATH=/ideation/
ENV VITE_APP_WS_SERVER_PATH=/ideation/socket.io/
RUN npm run build

# Serve with Nginx
FROM nginx:alpine

COPY --from=build /app/excalidraw-app/dist /usr/share/nginx/html

# Nginx config to handle SPA routing under /ideation
RUN echo 'server { \
    listen 80; \
    location / { \
    root /usr/share/nginx/html; \
    index index.html index.htm; \
    try_files $uri $uri/ /index.html; \
    } \
    }' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
