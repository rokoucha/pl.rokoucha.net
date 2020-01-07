FROM elixir:1.9-alpine

ENV UID=911 GID=911 \
    MIX_ENV=prod

ARG PLEROMA_REPOSITORY=https://git.pleroma.social/pleroma/pleroma.git
ARG PLEROMA_VER=v1.0.0

RUN apk -U upgrade \
    && apk add --no-cache \
       build-base \
       git \
       imagemagick \
       jq

RUN addgroup -g ${GID} pleroma \
    && adduser -h /pleroma -s /bin/sh -D -G pleroma -u ${UID} pleroma

USER pleroma
WORKDIR /pleroma

RUN git clone -b ${PLEROMA_VER} --depth 1 ${PLEROMA_REPOSITORY} /pleroma

RUN touch /pleroma/config/prod.secret.exs

RUN mix local.rebar --force \
    && mix local.hex --force \
    && mix deps.get \
    && mix compile

VOLUME /pleroma/uploads/

CMD ["mix", "phx.server"]

HEALTHCHECK --interval=1m --timeout=30s --retries=3 \
  CMD ["/bin/sh", "-c", "[ $(/usr/bin/wget -q -O - --header 'X-Forwarded-Proto: https' http://localhost:4000/api/pleroma/healthcheck | /usr/bin/jq -r .active) = '1' ]"]