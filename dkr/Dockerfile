
# cd ~/dkr && docker build -t bitshares .
# docker run -p 0.0.0.0:9777:9777 -v $PWD/data:/steem -d -t steem

FROM ubuntu:xenial
RUN apt-get update && \
	apt-get install -y gcc-4.9 g++-4.9 cmake make libbz2-dev libdb++-dev libdb-dev && \
	apt-get install -y libssl-dev openssl libreadline-dev autoconf libtool git && \
	apt-get install -y autotools-dev build-essential g++ libbz2-dev libicu-dev python-dev wget doxygen python3 python3-dev libboost-all-dev curl && \
        apt-get clean -qy
# P2P (seed) port
EXPOSE 7777
# RPC ports
EXPOSE 5000
EXPOSE 8090

ARG bitsharesd_version=0.1.8

RUN cd ~ && \
	git clone https://github.com/bitshares/bitshares-2 && \
	cd bitshares-2 && \
	git checkout ${bitsharesd_version} && \
	git submodule update --init --recursive && \
        cd ~/bitshares-2 && \
	cmake -DCMAKE_BUILD_TYPE=Release . && \
	make -j$(nproc) && make install && rm -rf ~/bitshares-2
VOLUME /bitshares
WORKDIR /bitshares

RUN echo "Please configure me! You need to mount a data directory onto /bitshares of this container to it to function correctly. (if you're using Bitshares-in-a-box most of this is handled automatically)"
CMD ["sh", "-c", "/usr/local/bin/witness_node"]
