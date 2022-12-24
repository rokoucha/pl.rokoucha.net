FROM docker.io/library/elixir:1.14-alpine AS build

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

RUN git clone --branch ${PLEROMA_VER} --depth 1 ${PLEROMA_REPOSITORY} /pleroma

RUN echo "import Config" > /pleroma/config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path release

FROM docker.io/library/alpine:3.16

ENV GID=911
ENV UID=911

ARG HOME=/opt/pleroma
ARG DATA=/var/lib/pleroma

RUN echo ${PLEROMA_VER} > /pleroma.ver

RUN apk -U upgrade \
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
