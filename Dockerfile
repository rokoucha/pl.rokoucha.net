FROM elixir:1.9-alpine AS build

ENV MIX_ENV=prod

ARG PLEROMA_REPOSITORY=https://git.pleroma.social/pleroma/pleroma.git
ARG PLEROMA_VER=develop

RUN apk -U upgrade && apk add --no-cache \
    gcc \
    git \
    make \
    musl-dev

WORKDIR /pleroma

RUN git clone -b develop ${PLEROMA_REPOSITORY} /pleroma \
    && git checkout ${PLEROMA_VER}

RUN touch /pleroma/config/prod.secret.exs

RUN && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path release

FROM alpine:3.13

ARG HOME=/opt/pleroma
ARG DATA=/var/lib/pleroma

RUN echo ${PLEROMA_VER} > /pleroma.ver

RUN apk -U upgrade && apk add --no-cache \
    exiftool \
    imagemagick \
    jq \
    libmagic \
    ncurses \
    && adduser --home ${HOME} --shell /bin/nologin --system pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA} \
    && mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma

USER pleroma

COPY --from=build --chown=pleroma:0 /pleroma/release ${HOME}

VOLUME ${DATA}/uploads/

EXPOSE 4000

HEALTHCHECK --interval=1m --timeout=30s --retries=3 CMD ["/bin/sh", "-c", "[ $(/usr/bin/wget -q -O - --header 'X-Forwarded-Proto: https' http://localhost:4000/api/pleroma/healthcheck | /usr/bin/jq -r .active) = '1' ]"]

CMD ["/opt/pleroma/bin/pleroma", "start"]
