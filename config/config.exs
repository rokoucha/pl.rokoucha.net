import Config

config :pleroma, Pleroma.Web.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  secure_cookie_flag: true,
  url: [host: "pl.rokoucha.net", scheme: "https", port: 443]

config :logger, level: :info

config :pleroma, :instance,
  description: "Rokoucha's Pleroma instance",
  email: "admin+pleroma@rokoucha.net",
  healthcheck: true,
  name: "Pleroma/Rokoucha",
  registrations_open: false,
  static_dir: "/var/lib/pleroma/static"

config :pleroma, :mrf,
  policies: [Pleroma.Web.ActivityPub.MRF.SimplePolicy]

config :pleroma, :assets,
  default_mascot: :no_mascot,
  mascots: [
    no_mascot: %{
      mime_type: "",
      url: ""
    }
  ]

config :pleroma, :mrf_simple,
  reject: [
    "mstdn.h3z.jp",
    "newjack.city"
  ]

config :pleroma, Pleroma.Upload,
  filters: [
    Pleroma.Upload.Filter.AnonymizeFilename,
    Pleroma.Upload.Filter.Mogrify
  ],
  strip_exif: false,
  uploader: Pleroma.Uploaders.S3

config :pleroma, Pleroma.Upload.Filter.Mogrify,
  args: [
    "auto-orient",
    "strip"
  ]

config :pleroma, Oban,
  queues: [
    background: 50,
    federator_incoming: 200,
    federator_outgoing: 200,
    mailer: 10,
    scheduled_activities: 100,
    transmogrifier: 20,
    web_push: 50
  ]

config :prometheus, Pleroma.Web.Endpoint.MetricsExporter,
  auth: false,
  enabled: true,
  format: :text,
  #ip_whitelist: ["172.16.2.11", "2400:2410:3021:4900:20c:29ff:fe8a:f7d7"],
  path: "/api/pleroma/app_metrics"

import_config "prod.secret.exs"
