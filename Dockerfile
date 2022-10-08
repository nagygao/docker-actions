FROM node:16-alpine as builder
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

FROM nginx
COPY --from=builder /app/dist/docker-actions/* /usr/share/nginx/html/