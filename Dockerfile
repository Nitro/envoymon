# ------------------------------------------------------------------------------
# Crystal Build Container
# ------------------------------------------------------------------------------
FROM crystallang/crystal:0.24.2 as builder
RUN mkdir /build
WORKDIR /build
RUN apt-get update && apt-get install -y libgc-dev

ADD envoymon.cr /build
ADD src /build/src

RUN crystal spec/
RUN crystal build --release envoymon.cr
