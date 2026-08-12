# Build stage
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
COPY web-app/package.json web-app/
COPY shared/package.json shared/
COPY shells/shared/package.json shells/shared/
RUN npm ci --workspace web-app
COPY . .
RUN npm run build

# Serve stage
FROM nginx:1.27-alpine
COPY --from=build /app/web-app/dist /usr/share/nginx/html
COPY infra/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ >/dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
