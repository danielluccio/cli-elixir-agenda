import Config

config :agenda_cli, run_cli: true

if config_env() == :test do
  import_config "test.exs"
end
