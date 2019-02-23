use Mix.Config

# Swarm is quite chatty at lower log levels, so we disable info & debug warnings.
config :logger, level: :warn

# We have Xgit.Lib.Config do its idle timeout much faster in test so we have
# a hope of covering the shutdown case.
config :xgit, :config_idle_timeout, 10
