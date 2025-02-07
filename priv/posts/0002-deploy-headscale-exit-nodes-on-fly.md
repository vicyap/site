%{
  title: "Deploy Headscale Exit Nodes on Fly",
  date: "2025-01-24",
  tags: ~w(networking)
}
---

## TLDR

In my previous [post](./deploy-a-headscale-server-on-fly), I described how to
deploy a [headscale](https://headscale.net/) server on
[fly.io](https://fly.io/).

In this post, I will go through how to deploy exit nodes that register to that
[headscale](https://headscale.net/) server on [fly.io](https://fly.io/).

If you just want to see the code, see my repo here:
https://github.com/vicyap/headscale-on-fly

## Why?

In my previous [post](./deploy-a-headscale-server-on-fly), I described why I
started this idea. The gist is that I was on a wifi network that blocked
`tailscale.com`, which prevented me from connecting to my remote development
machine. The solution was to deploy my own `headscale` server and connect my
devices to that.

However, since `tailscale.com` is blocked, I am also unable to access the
Tailscale docs at https://tailscale.com/kb.

A solution is to deploy another tailscale node and configure it to be an [exit
node](https://tailscale.com/kb/1103/exit-nodes).

So how should we deploy this exit node...? Well the `headscale` server is
already deployed with Fly, so why not Fly?

*I know I could simply configure my remote development machine as an exit node,
but deploying to Fly makes it easier to see what the bare minimum steps.*

## Deploy an Exit Node on Fly

### Fly Setup

I will assume you already have an account with [Fly](https://fly.io/) and you
have already logged into the CLI with:

```bash
fly auth login
```

### Dockerfile and Start Script

`Dockerfile`:

```dockerfile
FROM alpine:3.21.0

# Tailscale dependencies.
RUN apk update && apk add ca-certificates iptables ip6tables && rm -rf /var/cache/apk/*

# Copy Tailscale binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale

RUN mkdir -p /app /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
COPY start_tailscale.sh /app/start_tailscale.sh
```

`start_tailscale.sh`:

```sh
#!/bin/sh

# Enable IP Forwarding
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Start Tailscale
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
tailscale up --login-server=${HEADSCALE_URL} --hostname=${FLY_REGION} --advertise-exit-node
wait
```

Note: In `start_tailscale.sh`, `--hostname` is set to `FLY_REGION`. This flag
configures the name of the exit node. In my opinion, naming the exit node after
the region makes it easier to keep track of where the exit node is deployed.

`FLY_REGION` is an environment variable available to Fly Machines. See here for
a full list of available environment variables:
https://fly.io/docs/machines/runtime-environment/.

### Fly App Configuration

Next, use `fly launch --no-deploy` to create a Fly app and `fly.toml` file
without deploying it.

Here's an example with some hardcoded defaults:
```bash
fly launch --yes --no-deploy \
  --generate-name \
  --vm-size shared-cpu-1x \
  --volume-initial-size 1
```

Now, edit `fly.toml` and add the following additional configuration:
```ini
[processes]
  app = '/bin/sh /app/start_tailscale.sh'

[[mounts]]
  source = 'data'
  destination = '/var/lib/tailscale'
  initial_size = '1'

[[restart]]
  policy = 'always'

[env]
  HEADSCALE_URL = 'https://my-headscale.fly.dev'
```

Finally, remove the `[http_service]` section since this app does not expose any
http services. Keeping this section will cause an error during deploy because
Fly will expect the `internal_port` to be listening.

The final `fly.toml` file should look something like this:
```ini
app = 'some-name-1234'
primary_region = 'dfw'

[build]

[[vm]]
  size = 'shared-cpu-1x'

[processes]
  app = '/bin/sh /app/start_tailscale.sh'

[[mounts]]
  source = 'data'
  destination = '/var/lib/tailscale'
  initial_size = 1

[[restart]]
  policy = 'always'

[env]
  HEADSCALE_URL = 'https://my-headscale.fly.dev'
```

**Note**: Make sure you update `HEADSCALE_URL` to your `headscale` server's
domain.

### Deploy

At this point, your files should look like this:
```plaintext
.
├── Dockerfile
├── fly.toml
└── start_tailscale.sh
```

Now deploy:
```bash
fly deploy
```

## Register The Exit Node

After `fly deploy`, go to your `headscale` server logs.
```bash
# replace `my-headscale` with your headscale server's app name
fly --app my-headscale logs
```

You should see log messages that look like this:
```plaintext
2025-01-23T17:09:25Z app[328723dc429698] dfw [info]2025-01-23T17:09:25Z INF home/runner/work/headscale/headscale/hscontrol/auth.go:28 > Successfully sent auth url: https://some-name-1234.fly.dev:443/register/mkey:a4f099968d4c1207ab0b80d73691ba3c25726540bfbbc8422434dd8dd28a3222 expiry=-62135596800 followup=https://some-name-1234.fly.dev:443/register/mkey:a4f099968d4c1207ab0b80d73691ba3c25726540bfbbc8422434dd8dd28a3222 machine_key=[pPCZl] node=dfw node_key=[tB8Ik] node_key_old=
```

The important part of the message is `Successfully sent auth url: https://...`.
Go to this url to get the command you will need to run on your `headscale`
server to register the newly launched node.

Run the command on your `headscale` server. For example:

```bash
# replace `my-headscale` with your headscale server's app name
# replace `my-user` with your headscale user's name
fly --app my-headscale ssh console -C 'headscale nodes register --user my-user --key mkey:a4f099968d4c1207ab0b80d73691ba3c25726540bfbbc8422434dd8dd28a3222'
```

**Note**: To create a `headscale` user, run `headscale users create my-user`.
See my previous [post](./deploy-a-headscale-server-on-fly) for more details.

## Enable Exit Node Routes on Headscale

The final step is to enable the exit node routes. This can be done through `headscale routes`.

This is required because Tailscale requires an Owner, Admin or Network Admin to
allow a device to be an exit node for the tailnet. See their docs for more info
here: https://tailscale.com/kb/1103/exit-nodes.

### List Routes

To list routes:

```bash
# replace `my-headscale` with your headscale server's app name
fly --app my-headscale ssh console -C 'headscale routes list'
```

Notice `Enabled` is `false`.

```plaintext
ID | Node | Prefix    | Advertised | Enabled | Primary
1  | dfw  | ::/0      | true       | false   | -
2  | dfw  | 0.0.0.0/0 | true       | false   | -
```


### Enable Routes

Now enable each route

```bash
# replace `my-headscale` with your headscale server's app name
fly --app my-headscale ssh console -C 'headscale routes enable -r 1'
fly --app my-headscale ssh console -C 'headscale routes enable -r 2'
```

List the routes and verify that they are enabled.

```bash
# replace `my-headscale` with your headscale server's app name
fly --app my-headscale ssh console -C 'headscale routes list'
```

Notice `Enabled` is `true`.

```plaintext
ID | Node | Prefix    | Advertised | Enabled | Primary
1  | dfw  | ::/0      | true       | true    | -
2  | dfw  | 0.0.0.0/0 | true       | true    | -
```

## Conclusion

Congrats! You should now be able to route your traffic through exit nodes deployed on Fly.

## Bonus - Deploy to Another Region

If you want, you can deploy multiple exit nodes, each to a different Fly region.

To do so, use `fly machine clone` to clone your existing fly machine to another
region.

Run `fly machine list` to list your machines. Get the ID of your existing exit
node.

Run `fly platform regions` to see the list of regions that are available.

Finally, run `fly machine clone <machine-id> -r <fly-region-code>`.
