use Mix.Config

# We have Xgit.Lib.Config do its idle timeout much faster in test so we have
# a hope of covering the shutdown case.
config :xgit, :config_idle_timeout, 10
