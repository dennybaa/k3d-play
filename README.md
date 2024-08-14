# k3d play

Bootstraps cluster named `play` with:

  - cert-manager self-signed CA
  - traefik ingress
  - redirects localhost:80/443 to the ingress

## Required tools

 - podman
 - helm
 - helmfile
 - kubeswitch (switcher binary)
 - justfile

The CA certificate file is written into `ca-cert.pem` and can be imported into the browser for secure `*.localhost` `*.play.localhost` connections. Chrome doesn't trust `*.localhost` by default, thus cert-manager should be used to issue certificates (see bitnami tls example bellow).

## Usage

```shell
just
# or
just destroy
```

## Tips

### bitnami tls

```yaml
ingress:
  enabled: true
  tls: true
  hostname: host.localhost
  annotations:
    kubernetes.io/tls-acme: "true"
```
