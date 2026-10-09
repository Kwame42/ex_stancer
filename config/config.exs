import Config

config :stancer,
  api_key: System.get_env("STANCER_API_KEY") || "your_test_key_here",
  api_url: "https://api.stancer.com",
  api_version: "v1"
