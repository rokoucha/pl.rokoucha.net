FROM elixir:1.9-alpine AS build

ENV MIX_ENV=prod

ARG PLEROMA_REPOSITORY=https://git.pleroma.social/pleroma/pleroma.git
ARG PLEROMA_VER=develop

RUN apk -U upgrade && apk add --no-cache \
    cmake \
    file-dev \
    g++ \
    gcc \
    git \
    make \
    musl-dev

WORKDIR /pleroma

RUN git clone -b develop ${PLEROMA_REPOSITORY} /pleroma \
    && git checkout ${PLEROMA_VER}

RUN echo "import Config" > /pleroma/config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path release

FROM alpine:3.13

ENV GID=911
ENV UID=911

ARG HOME=/opt/pleroma
ARG DATA=/var/lib/pleroma

RUN echo ${PLEROMA_VER} > /pleroma.ver

RUN echo "https://sjc.edge.kernel.org/alpine/latest-stable/community" >> /etc/apk/repositories \
    && apk -U upgrade \
    && apk add --no-cache \
    exiftool \
    imagemagick \
    libmagic \
    ncurses \
    postgresql-client \
    && addgroup -g ${GID} pleroma \
    && adduser -h ${HOME} -s /bin/nologin -D -G pleroma -u ${UID} pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R ${UID}:${GID} ${DATA} \
    && mkdir -p /etc/pleroma \
    && chown -R ${UID}:${GID} /etc/pleroma

USER pleroma

COPY --from=build --chown=${UID}:${GID} /pleroma/release ${HOME}

VOLUME ${DATA}/uploads/

EXPOSE 4000

CMD ["/opt/pleroma/bin/pleroma", "start"]
