import Config

config :hailstorm, Hailstorm,
  host_socket_url: '127.0.0.1',
  host_web_url: "localhost:4000",
  websocket_url: "ws://localhost:4000/tachyon/websocket",
  spring_ssl_port: 8201,
  ssl_port: 8202,
  password: "password"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: "/tmp/hailstorm_error.log",
  level: :error

config :logger, :info_log,
  path: "/tmp/hailstorm_info.log",
  level: :info
