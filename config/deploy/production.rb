server "3.86.201.40", user: "deploy", roles: %w[app db web],
  ssh_options: {
    keys: %w[~/.bta/id_rsa],
    forward_agent: true,
    auth_methods: %w[publickey]
  }

set :branch, "main"
