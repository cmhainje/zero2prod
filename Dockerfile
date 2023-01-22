FROM rust:1.63.0
WORKDIR /app

# install system deps for linking
RUN apt update && apt install lld clang -y

# copy source code from working environment to Docker image
COPY . .

# build it for release
RUN cargo build --release

# launch the binary when `docker run` is executed
ENTRYPOINT ["./target/release/zero2prod"]