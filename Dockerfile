FROM rust:alpine AS backend
WORKDIR /home/rust/src
RUN apk --no-cache add musl-dev openssl-dev
COPY . .
RUN cargo test --release
RUN cargo build --release

FROM amd64/rust:alpine AS wasm
WORKDIR /home/rust/src
RUN apk --no-cache add curl musl-dev
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
COPY . .
RUN wasm-pack build --target web letsmarkdown-wasm

FROM amd64/node:lts-alpine AS frontend
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
COPY --from=wasm /home/rust/src/letsmarkdown-wasm/pkg letsmarkdown-wasm/pkg
RUN npm install -g pnpm corepack
RUN pnpm i
COPY . .
RUN pnpm build

FROM scratch
COPY --from=frontend /usr/src/app/dist dist
COPY --from=backend /home/rust/src/target/release/letsmarkdown-server .
USER 1000:1000
CMD [ "./letsmarkdown-server" ]
