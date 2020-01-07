use Mix.Config

config :pleroma, Pleroma.Web.Endpoint,
   url: [host: "localhost", scheme: "http", port: 4000],
   http: [ip: {0, 0, 0, 0}, port: 4000]

config :logger, level: :info

config :pleroma, :instance,
  name: "Pleroma/Test",
  email: "admin+pleroma@rokoucha.net",
  description: "Rokoucha's Pleroma testing instance",
  registrations_open: false,
  healthcheck: true,
  static_dir: "/pleroma/static"

config :pleroma, :assets,
  mascots: [
    no_mascot: %{
      url: "",
      mime_type: ""
    }
  ],
  default_mascot: :no_mascot

config :pleroma, Pleroma.Upload,
  uploader: Pleroma.Uploaders.Local,
  strip_exif: false,
  filters: [
    Pleroma.Upload.Filter.AnonymizeFilename,
    Pleroma.Upload.Filter.Mogrify
  ]

config :pleroma, Pleroma.Uploaders.Local,
  uploads: "/pleroma/uploads"

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