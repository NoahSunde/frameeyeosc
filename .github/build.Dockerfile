# The release build for this fork, on GitHub's arm64 runners (.github/workflows/release.yml). The same Rust image
# scripts/package.sh builds the Rust programs in (Debian bookworm, glibc 2.36, so they start on older SteamOS), with
# what the panel needs on top: its build tools and libraries, Noto Sans CJK where SteamOS keeps it (the panel's tests
# render text), and Valve's libopenvr_api.so where SteamVR has it on the Frame (the panel links against it; at run
# time the Frame's own copy is used).
FROM docker.io/library/rust:1.98.1-slim-bookworm@sha256:3ebe98baef5911f8461cf81ba05644374a3c5ef1f8a33db3977bd4175f5ff1fc

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils ca-certificates cmake curl fonts-noto-cjk fonts-noto-cjk-extra g++ libcairo2-dev libfreetype-dev \
        libvulkan-dev ninja-build pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/fonts/noto-cjk \
    && for w in Regular Bold; do \
        f="$(find /usr/share/fonts -name "NotoSansCJK-$w.ttc" | head -n 1)"; \
        test -n "$f" && ln -s "$f" "/usr/share/fonts/noto-cjk/NotoSansCJK-$w.ttc"; \
    done

ARG OPENVR_TAG=v2.15.6
RUN mkdir -p /opt/steamvr/bin/linuxarm64 \
    && curl -fsSL -o /opt/steamvr/bin/linuxarm64/libopenvr_api.so \
        "https://raw.githubusercontent.com/ValveSoftware/openvr/${OPENVR_TAG}/bin/linuxarm64/libopenvr_api.so"
