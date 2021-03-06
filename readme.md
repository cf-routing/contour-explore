# Contour Explore

This repo contains yaml proofs of how the capabilities of Contour can satisfy
ingress outcomes for cf-for-k8s.

## Setup

Start with a 1.17 or newer kubernetes cluster.

Install Contour via quickstart:
```
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

Deploy a workload to test connectivity:
```
kubectl apply -f https://projectcontour.io/examples/kuard.yaml
```

Wait some time (30-60 seconds) for GCP to provision an IP, then assign it to a
variable:
```
EXTERNAL_IP=`kubectl get -n projectcontour service envoy -o wide | awk 'NR > 1 {print $4}'`
```

Check connectivity:
```
curl $EXTERNAL_IP
```

If successful, clean up:
```
kubectl delete -f https://projectcontour.io/examples/kuard.yaml
```

Install prereqs for proofs below:
```
kubectl apply -f prereqs.yml
```

## Basic ingress http routing via FQDN to apps and system components

Apply resources:
```
kubectl apply -f basic-ingress-via-fqdn.yml
```

Test:
```
curl -HHost:proxy.network $EXTERNAL_IP
curl -HHost:httpbin.example.com $EXTERNAL_IP
```

Clean up:
```
kubectl delete -f basic-ingress-via-fqdn.yml
```

## Ingress routing to apps and system components via context paths
Apply resources:
```
kubectl apply -f ingress-via-context-paths.yml
```

Test:
```
curl -HHost:foo.bar.com $EXTERNAL_IP
curl -HHost:foo.bar.com $EXTERNAL_IP/anything
```

`foo.bar.com` reaches the Proxy app, but the `/anything` path reaches httpbin.

Clean up:
```
kubectl delete -f ingress-via-context-paths.yml
```

**Notes**: One `Ingress` object is used in this example which mirrors how we
create `VirtualServices` now, but we could also create separate `Ingress`
objects and have the same user experience.

## Mapping multiple routes to apps

Apply resources:
```
kubectl apply -f multiple-routes-to-app.yml
```

Test:
```
curl -HHost:foo.bar.com $EXTERNAL_IP
curl -HHost:bar.foo.com $EXTERNAL_IP
```

Clean up:
```
kubectl delete -f multiple-routes-to-app.yml
```

## Mapping multiple apps to a single route

Apply resources:
```
kubectl apply -f multiple-apps-to-route.yml
```

Test:
```
curl -HHost:multiapp.example.com $EXTERNAL_IP # do this repeatedly, observe changing result
```

Clean up:
```
kubectl delete -f multiple-apps-to-route.yml
```

**Notes**: Kubernetes `Ingress` objects do not support multiple backends, so we
have to create a single service that selects all the apps. This means **only
round-robin balancing** and **no weighted routing** of any kind. It also means we will
have to label app pods with all the routes that select them which is an exciting
kind of nightmare. However, Contour's own `HTTPProxy` resource does support
multiple backends and weighted routing, so we could use that.

## Encryption and authentication between the client and gateway (TLS at a minimum)

Apply resources:
```
kubectl apply -f tls.yml
```

Test:
```
curl -k --resolve tls.example.com:443:$EXTERNAL_IP https://tls.example.com/anything
```

Clean up:
```
kubectl delete -f tls.yml
```

## Mutual authentication between client and gateway

Install HTTPProxy CRD:
```
kubectl apply -f https://raw.githubusercontent.com/projectcontour/contour/release-1.8/examples/contour/01-crds.yaml
```

Apply resources:
```
kubectl apply -f mtls.yml
```

Test:
```
curl --key certs/client.key --cert certs/client.crt -k --resolve mtls.example.com:443:$EXTERNAL_IP https://mtls.example.com/anything
```

Clean up:
```
kubectl delete -f mtls.yml
```

**Notes**: This is not possible with Kubernetes `Ingress` objects (yet?) so we
had to install the HTTPProxy CRD. This may mean that we can't use `Ingress`, at
least until it supports client certificate validation. Some other ingress
systems (notably nginx-ingress) use annotations on the `Ingress` object to
specify the client secret, and
[Contour](https://projectcontour.io/docs/main/annotations/) supports that
pattern, so we may be able to ask them to add client validation fields as
options there.
