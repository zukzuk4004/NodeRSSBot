FROM node:16-alpine as ts-builder
WORKDIR /app
COPY . /app
RUN npm i -g pnpm && pnpm i --ignore-scripts && pnpm run build

FROM node:16-alpine as dep-builder
WORKDIR /app
COPY package.json pnpm-lock.yaml /app/
COPY tools /app/tools
RUN apk add --no-cache --update build-base python2 python3
COPY --from=ts-builder /app/dist /app/dist
RUN npm i -g pnpm && pnpm install --frozen-lockfile && node tools/minify-docker.js && sh tools/clean-nm.sh

FROM node:16-alpine as app
WORKDIR /app
ENV NODE_PRODUTION true
COPY data /app/data
COPY logs /app/logs
COPY package.json /app/package.json
COPY --from=ts-builder /app/dist /app/dist
COPY --from=dep-builder /app/node_modules-minimal/node_modules /app/node_modules
CMD pnpm run start-docker
