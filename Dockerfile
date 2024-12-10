FROM ubuntu:24.04 AS builder

RUN --mount=type=cache,target=/var/cache/apt,id=builder-apt-cache \
    --mount=type=cache,target=/var/lib/apt,id=builder-apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        liblzma-dev \
        liblzo2-dev \
        patch \
        zlib1g-dev \
    && mkdir -p /sasquatch

WORKDIR /sasquatch

ADD https://downloads.sourceforge.net/project/squashfs/squashfs/squashfs4.4/squashfs4.4.tar.gz .
RUN tar -zxvf squashfs4.4.tar.gz

COPY patches /sasquatch/patches
RUN patch -d squashfs4.4 -p1 < patches/0_sasquatch_4.4.patch && \
    patch -d squashfs4.4 -p1 < patches/1_fix_dangling_pointer.patch && \
   cd squashfs4.4/squashfs-tools && \
   make

FROM ubuntu:24.04

RUN --mount=type=cache,target=/var/cache/apt,id=runtime-apt-cache \
    --mount=type=cache,target=/var/lib/apt,id=runtime-apt-lib \
    apt-get update && \
    apt-get install -y --no-install-recommends \
       liblzma5 \
       liblzo2-2 \
       zlib1g

COPY --from=builder /sasquatch/squashfs4.4/squashfs-tools/sasquatch /usr/local/bin/sasquatch

WORKDIR /work

ENTRYPOINT [ "/usr/local/bin/sasquatch" ]
