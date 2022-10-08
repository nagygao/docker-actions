FROM node:16-alpine as builder
WORKDIR /app
RUN npm install -g npm@8.19.2
COPY . .
RUN npm install
RUN ng build

FROM nginx
COPY --from=builder /build/dist/docker-actions/ /usr/share/nginx/html/