FROM ubuntu:16.04

RUN apt-get update \
    && apt-get -qq --no-install-recommends install \
        libmicrohttpd10 \
        libssl1.0.0 \
        libhwloc5 \
    && rm -r /var/lib/apt/lists/*

ENV XMR_STAK_CPU_VERSION v1.3.0-1.5.0

RUN set -x \
    && buildDeps=' \
        ca-certificates \
        cmake \
        curl \
        g++ \
        libmicrohttpd-dev \
        libssl-dev \
        libhwloc-dev \
        make \
    ' \
    && apt-get -qq update \
    && apt-get -qq --no-install-recommends install $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    \
    && mkdir -p /usr/local/src/xmr-stak-cpu/build \
    && cd /usr/local/src/xmr-stak-cpu/ \
    && curl -sL https://github.com/fireice-uk/xmr-stak-cpu/archive/$XMR_STAK_CPU_VERSION.tar.gz | tar -xz --strip-components=1 \
    && sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' donate-level.h \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && cp bin/xmr-stak-cpu /usr/local/bin/ \
    && sed -r \
    -e 's/^null,/[\n \
     { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 0 },\n \
     { "low_power_mode" : false, "no_prefetch" : true, "affine_to_cpu" : 1 },\n \
],/'\
        -e 's/^("pool_address" : ).*,/\1"pool.xmr.pt:3333",/' \
        -e 's/^("wallet_address" : ).*,/\1"42CqKuH8eCe7E1K9hBHG4iEDwcWXnCr39B7JvByAVqyfhekWNMST2UGS2CW5cYxYDL6GeZN7DX3dEUjyWDY23SbVEyussuC",/' \
        -e 's/^("pool_password" : ).*,/\1"docker-xmr-stak-cpu:x",/' \
        ../config.txt > /usr/local/etc/config.txt \
    \
    && rm -r /usr/local/src/xmr-stak-cpu \
    && apt-get -qq --auto-remove purge $buildDeps

ENTRYPOINT ["xmr-stak-cpu"]
CMD ["/usr/local/etc/config.txt"]
