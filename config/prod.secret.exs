import Config

config :pleroma, Pleroma.Web.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  url: [host: "localhost", scheme: "http", port: 4000]

config :logger, level: :info

config :pleroma, :instance,
  description: "Rokoucha's Pleroma testing instance",
  email: "admin+pleroma@rokoucha.net",
  healthcheck: true,
  name: "Pleroma/Test",
  registrations_open: false,
  static_dir: "/var/lib/pleroma/static"

config :pleroma, :assets,
  default_mascot: :no_mascot
  mascots: [
    no_mascot: %{
      mime_type: "",
      url: ""
    }
  ],

config :pleroma, Pleroma.Upload,
  filters: [
    Pleroma.Upload.Filter.AnonymizeFilename,
    Pleroma.Upload.Filter.Mogrify
  ],
  strip_exif: false,
  uploader: Pleroma.Uploaders.Local


config :pleroma, Pleroma.Uploaders.Local,
  uploads: "/var/lib/pleroma/uploads"

config :pleroma, Pleroma.Upload.Filter.Mogrify,
  args: [
    "auto-orient"
    "strip",
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

import_config "keys.secret.exs"