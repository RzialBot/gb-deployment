FROM node:12.16.3-alpine AS build-env
ADD . /app
WORKDIR /app

RUN npm i --production

FROM gcr.io/distroless/nodejs
COPY --from=build-env /app /app
WORKDIR /app

EXPOSE 8081
CMD ["src/main.js"]
