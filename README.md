# Matrix: Synapse Environment

## Provides

- [Synapse](https://github.com/matrix-org/synapse)
- [Caddy](https://caddyserver.com)
- [PostgreSQL](https://www.postgresql.org)

## Requirements

The host machine or VM requires:

- [Docker](https://www.docker.com/get-started/)
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
- `envsubst`, which is included with [gettext](https://en.wikipedia.org/wiki/Gettext)

## Getting Started

1. Clone the repo
2. Copy `.env.example` to `.env` and edit it
3. Run `./setup.sh`
4. If you need to make local changes to configuration, do so to the files the setup script copied into the data directories:
   1. `$SYNAPSE_DATA_PATH/synapse/homeserver.yaml`
   2. `$SYNAPSE_DATA_PATH/synapse/log.yaml`
   3. `$CADDY_DATA_PATH/caddy/Caddyfile`
5. Set up the following `A` records in your domain's DNS settings (in these examples, `example.com` is the same value you configured as `$SYNAPSE_SERVER_NAME` in the `.env` file):
   1. `matrix.example.com` should point to the IP address of the server where you'll run `docker-compose`; this is your *Matrix homeserver*
   2. `example.com` is your *primary domain* that forms the domain portion of your Matrix username (i.e., `@yourname:example.com`), where you'll add `.well-known` files to tell other Matrix servers how to find your account and homeserver; this domain can be served from the same server, but it's not served by the environment defined by this repository—most likely, you'll serve it from a different server, and it might be your primary website
6. Add the `.well-known` files to your primary domain (see below)
7. Make sure your firewall allows ports 80, 443, and 8448; for example, on Ubuntu, do: `ufw allow www && ufw allow https && ufw allow 8448`
8. Start this environment with containers daemonized: `docker compose up -d`

## `.well-known` files for Matrix

- [Matrix Client-Server API, Server Discovery](https://spec.matrix.org/latest/client-server-api/#server-discovery)
- [Matrix Server-Server API, Resolving server names](https://spec.matrix.org/v1.8/server-server-api/#resolving-server-names)

On the primary domain that forms the domain portion of your Matrix username (i.e., `@yourname:example.com`), add the following two files and ensure they respond with an HTTP header of `Access-Control-Allow-Origin: *` for CORS:

- `/.well-known/matrix/server`
- `/.well-known/matrix/client`

### Contents of `.well-known/matrix/server`

```json
{
    "m.server": "matrix.example.com:443"
}
```

### Contents of `.well-known/matrix/client`

```json
{
    "m.homeserver": {
        "base_url": "https://matrix.example.com",
        "server_name": "example.com"
    },
    "m.identity_server": {
        "base_url": "https://vector.im"
    }
}
```
