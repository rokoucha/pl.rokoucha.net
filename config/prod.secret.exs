use Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
   url: [host: "pl.rokoucha.net", scheme: "https", port: 443],
   http: [ip: {0, 0, 0, 0}, port: 4000]

config :logger, level: :info

config :pleroma, :instance,
  name: "Pleroma/Rokoucha",
  email: "admin+pleroma@rokoucha.net",
  limit: 5000,
  description: "Rokoucha's Pleroma instance",
  finmoji_enabled: false,
  registrations_open: false,
  rewrite_policy: Pleroma.Web.ActivityPub.MRF.SimplePolicy

config :pleroma, :mrf_simple,
  reject: ["newjack.city", "mstdn.h3z.jp", "misskey.io"],
  media_removal: ["mstdn.jp"]

config :pleroma, Pleroma.Upload,
  uploader: Pleroma.Uploaders.S3,
  strip_exif: false,
  filters: [
    Pleroma.Upload.Filter.AnonymizeFilename,
    Pleroma.Upload.Filter.Mogrify
  ]

config :pleroma, Pleroma.Upload.Filter.Mogrify,
  args: [
    "strip",
    "auto-orient"
  ]

config :pleroma, Oban,
  queues: [
    federator_incoming: 200,
    federator_outgoing: 200,
    web_push: 50,
    mailer: 10,
    transmogrifier: 20,
    scheduled_activities: 100,
    background: 50
  ]

import_config "keys.secret.exs"

