%{
  title: "Deploy Headscale on Fly (Part 1)",
  date: "2025-01-22",
  tags: ~w(networking)
}
---

## TLDR

This blog post will go through how to deploy [headscale](https://headscale.net/)
on [fly.io](https://fly.io/).

If you just want to see the code, see my repo here:
https://github.com/vicyap/headscale-on-fly

## Why?

I started this idea because I was recently on a wifi network that blocked access
to `tailscale.com` because it was considered a "VPN". This prevented my
Tailscale client from starting because it connects to
`controlplane.tailscale.com`. This was a problem for me because I do a lot of
development work on a remote machine that I connect to using Tailscale.

So, I wanted to figure out a way to connect to my remote machine. That's when I
discovered [headscale](https://headscale.net/).

### What is Headscale?

From their [docs](https://headscale.net/): *Headscale is an open source,
self-hosted implementation of the Tailscale control server.*

The Tailscale control server, aka the [coordination
server](https://tailscale.com/kb/1508/control-data-planes#coordination-server),
handles device discovery, authentication, key distribution and policy
enforcement.

Typically, Tailscale clients connect to https://controlplane.tailscale.com,
however, this can be changed with the following:
```bash
tailscale up --login-server https://my-headscale.example.com
```

So, we just need to run our own `headscale` server and connect our devices to it.

### Why Fly?

I decided to deploy with [fly.io](https://fly.io/) because they make it easy to
deploy a container to a public domain address with https in seconds. This means
we don't need to buy a domain.

For example, when you deploy an app on Fly, it will automatically be hosted at
`app-name.fly.dev`.

## Deploy Headscale on Fly

### Fly Setup

First, make sure you already have an account with [Fly](https://fly.io/).

Then, make sure you have installed their `fly` CLI:
https://fly.io/docs/flyctl/install/.

Now, log in with the CLI:
```bash
fly auth login
```

### Headscale Dockerfile

Create the following `Dockerfile`.
```dockerfile
FROM alpine:3.21.0

COPY --from=headscale/headscale:v0.23.0 /ko-app/headscale /usr/local/bin/headscale
```

Why not use `headscale/headscale:v0.23.0` directly?

Later on, we will need to run commands in the `headscale` container which
require the `headscale` docker image to have a shell.
`headscale/headscale:v0.23.0` does not have a shell by default. So a simple
solution is to copy the `headscale` binary into an `alpine` image.

### Fly App Configuration

Next, use `fly launch --no-deploy` to create a Fly app and `fly.toml` file
without deploying it.

Here's an example with hardcoded some defaults:
```bash
fly launch --yes --no-deploy \
  --generate-name \
  --vm-size shared-cpu-1x \
  --vm-memory 256 \
  --volume-initial-size 1
```

Now, edit `fly.toml` and add some additional configuration:
```ini
[processes]
  app = 'headscale serve'

[[mounts]]
  source = 'data'
  destination = '/var/lib/headscale'
  initial_size = '1'

[[files]]
  guest_path = '/etc/headscale/config.yaml'
  local_path = 'config.yaml'

[[restart]]
  policy = 'always'
```

### Headscale Configuration

Lastly, you will need to download and edit a `config.yaml` for `headscale`.

Download:
```bash
curl -s -o config.yaml https://raw.githubusercontent.com/juanfont/headscale/refs/tags/v0.23.0/config-example.yaml
```

Edit the following:
* `server_url`: This is based on your Fly App's name. See `fly.toml` for the app
  name. For example, if the app name is `my-headscale`, then this should be
  `https://my-headscale.fly.dev:443`.
* `listen_addr`: `0.0.0.0:8080`

More configuration options can be found here:
https://github.com/juanfont/headscale/blob/v0.23.0/config-example.yaml

### Deploy

At this point, your files should look like this:
```plaintext
.
├── Dockerfile
├── config.yaml
└── fly.toml
```

Now deploy:
```bash
fly deploy
```

At the end of that command, you should see something like:
```plaintext
Visit your newly deployed app at https://my-headscale.fly.dev/
```

You can test your app by making a GET request to its `/health` path.
```bash
curl https://my-headscale.fly.dev/health
```

Which should return:
```plaintext
{"status":"pass"}
```

If you want to view logs, run the following:
```bash
fly logs
```

### Running Commands on the Headscale Server

Throughout the rest of this guide, you will need to run commands on the
headscale server.

To run commands on the headscale server, use the following template:
```bash
fly ssh console -C 'headscale --help`
```

## Connecting Devices

Finally, we are ready to connect out devices to our headscale server.

### Create a Headscale User

Once the headscale server is running, you will need to create a user.

In headscale, a node (aka machine or device) is always assigned to a specific
user.

To create a user, run the following (the username does not matter):
```bash
fly ssh console -C 'headscale users create my-user'
```

### Connecting a Tailscale Client

To connect your device, run the following:
```bash
tailscale login --login-server https://my-headscale.fly.dev
```

This should print a url for you to authenticate. The url's format will be
something like: `/register/mkey:abcd1234` where `abcd1234` is a long hex string.

Now register that node to your headscale user.
```bash
fly ssh console -C 'headscale nodes register --user my-user --key mkey:abcd1234'
```

To connect other devices, see the headscale docs here:
* [android](https://headscale.net/stable/usage/connect/android/)
* [apple](https://headscale.net/stable/usage/connect/apple/)
* [windows](https://headscale.net/stable/usage/connect/windows/)

## What's Next?

Congrats! You have deployed `headscale` on Fly and connected your first device.

In an upcoming part 2, I will go over how to run an exit node. This will allow
you to access websites that were previously blocked, like the Tailscale docs at
https://tailscale.com/kb.
