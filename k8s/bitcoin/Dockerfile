FROM debian:12.8 AS build

WORKDIR /root

RUN apt-get update
RUN apt-get install --yes build-essential libtool autotools-dev automake \
  pkg-config bsdmainutils python3 libevent-dev libboost-dev git

RUN git clone https://github.com/bitcoin/bitcoin.git
WORKDIR bitcoin
RUN git checkout v28.0

RUN ./autogen.sh
RUN ./configure --disable-wallet --disable-tests --with-gui=no
RUN make
RUN make install

FROM debian:12.8 AS main

COPY --from=build /usr /usr
COPY ./bitcoin.conf bitcoin.conf

EXPOSE 8332 8333

CMD ["bitcoind", "--conf=/bitcoin.conf"]