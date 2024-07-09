# Local setup for test blue-green deployment

ALl tests were done using minikube with installed all services from `operator` directory

## Detailed steps done during testing
1. Spin up new `green` cluster
2. enable federation on `blue` and `green` cluster
```
    additionalPlugins: [ "rabbitmq_federation", "rabbitmq_federation_management" ]

```
1. Create sample existing exchange/queue on `blue` cluster  
  - one with classic queue on source
Exchange: Concent.Cases.API.Features.Documents:DocumentPublishedIntegrationEvent | fanout | durable

4. Create the queue on the `green` cluster but using `quorum` type
5. Enable federation link
6. Enable policy


Federation upstream:
virtual host:    first
name:            federation-first-link
URI:             amqp://admin:password@rabbitmq-cluster.rabbitmq-blue.svc.cluster.local:5672

virtual host:   second
name:           federation-second-link
URI:            amqp://admin:password@rabbitmq-cluster.rabbitmq-blue.svc.cluster.local:5672

Policies:
Virtual host:         first
name:                 federate-vhost-first
pattern:              ^.*$
apply to:             Queues
federation-upstream:  federation-first-link

Virtual host:         second
name:                 federate-vhost-second
pattern:              ^.*$
apply to:             Queues
federation-upstream:  federation-second-link


## Example of production setup
Production ready 4CPU, 10Gi RAM, storageClassName: ssd storage: "500Gi"
https://github.com/rabbitmq/cluster-operator/blob/59c0b45b94975d5029f4a6cec4bd8cc4826ce72d/docs/examples/production-ready/rabbitmq.yaml

## See locally

k port-forward -n rabbitmq-blue rabbitmq-cluster-server-0 15672:15672
k port-forward -n rabbitmq-green rabbitmq-cluster-server-0 15673:15672

## Other topics
- Maybe use external service to make a host:
https://kubernetes.io/docs/concepts/services-networking/service/#externalname
- Verify that uninstall will work
- what with rolling upgrade to image with newer version

## Federation on the queue level test

- url with user, password and host
amqp://admin:password@localhost:5672/second

- set up `Producer` (blue cluster)

```bash

kubectl run -it --rm perf-test-producer --namespace rabbitmq-blue --image=pivotalrabbitmq/perf-test:latest --restart=Never -- --uri amqp://admin:password@rabbitmq-cluster:5672/second --producers 1 --consumers 0 --autoack --size 1000 -f persistent --auto-delete false --queue Concent.Cases.API.Features.Import.Cases.ImportCaseIntegrationCommand_Execute --time 60
```

- set up `Consumer` (green cluster)
```bash
kubectl run -it --rm perf-test-consumer --namespace rabbitmq-green --image=pivotalrabbitmq/perf-test:latest --restart=Never -- --uri amqp://admin:password@rabbitmq-cluster:5672/second --producers 0 --consumers 2 --autoack --size 1000 --quorum-queue --queue Concent.Cases.API.Features.Import.Cases.ImportCaseIntegrationCommand_Execute --auto-delete false --time 120
```

- set up `Consumer (green cluster) for SAC queue
```bash
kubectl run -it --rm perf-test-consumer --namespace rabbitmq-green --image=pivotalrabbitmq/perf-test:latest --restart=Never -- --uri amqp://admin:password@rabbitmq-cluster:5672/second --producers 0 --consumers 1 --autoack --size 1000 --quorum-queue --queue-args x-single-active-consumer=true --queue Concent.Cases.API.Features.Import.Cases.ImportCaseSacIntegrationCommand_Execute --auto-delete false --time 120
```


## Export definitions from cluster

- Log to the rabbitmq cluster
```bash
k exec -it rabbitmq-cluster-server-0 -- /bin/sh
```

- Generate definitions for whole cluster

```bash
rabbitmqctl export_definitions cluster.definitions.json
```

- Copy definitions to local host

```bash
kubectl exec -n lighthouse rabbitmq-cluster-server-0 -- tar cf - /var/lib/rabbitmq/no.export.json | tar xf - -C .
```

- Filter file to get only one for e.g. `no` vhost

```bash
jq  '.queues[] | select(.vhost == "no")' no.definitions.json | jq -s > out-no.queues.json
```
```bash
jq  '.exchanges[] | select(.vhost == "no")' no.definitions.json | jq -s > out-no.exchanges.json
```
```bash
jq  '.bindings[] | select(.vhost == "no")' no.definitions.json | jq -s > out-no.bindings.json
```

- Combine output from those files into structure

```json
{
    "rabbit_version": "3.8.19",
    "parameters": [],
    "policies": [],
    "queues": [],
    "exchanges": [],
    "bindings": []
}
```

## Run scripts from inside the cluster

Mount disk for minikube node
```bash
minikube mount '/mnt/c/work/gh/rabbitmq-playground:/rabbitmq'
# or
minikube start --mount --mount-string /mnt/c/work/gh/rabbitmq-playground:/rabbitmq
```

Run pod with mounted scripts
```bash
kubectl run myubuntu --image ubuntu:22.04 --rm -it --restart=Never --overrides='
{
    "spec": {
        "containers": [
            {
                "name": "myubuntu",
                "image": "ubuntu:22.04",
                "stdin": true,
                "tty": true,
                "args": [ "bash" ],
                "volumeMounts": [
                    {
                        "name": "host-volume",
                        "mountPath": "/rabbitmq"
                    }
                ]
            }
        ],
        "volumes": [
            {
                "name": "host-volume",
                "hostPath": {
                    "path": "/rabbitmq"
                }
            }
        ]
    }
}
'
```


```bash
kubectl run myubuntu --image ubuntu:22.04 --rm -it -- /bin/sh
```