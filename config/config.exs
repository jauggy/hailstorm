import Config

config :beans, Beans,
  host_socket_url: '127.0.0.1',
  host_api_url: 'localhost:4000',
  port: 8202,
  password: "password"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :error_log,
  path: "/tmp/beans_error.log",
  level: :error

config :logger, :info_log,
  path: "/tmp/beans_info.log",
  level: :info
