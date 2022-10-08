FROM node:16-alpine as builder
RUN npm install
RUN ng build

FROM nginx
COPY --from=builder ./dist/docker-actions/ /usr/share/nginx/html/