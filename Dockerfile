FROM postgres:16-alpine

# Szükséges csomagok telepítése, beleértve az llvm fejlesztői eszközöket
RUN apk add --no-cache \
    postgresql-contrib \
    build-base \
    git \
    clang \
    llvm-dev && \
    git clone https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && make install && \
    cd .. && rm -rf pgvector

# Init SQL script másolása a konténerbe
COPY init.sql /docker-entrypoint-initdb.d/
