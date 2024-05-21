# Instruction to upgrade RabbitMQ from 3.8.x to latest version

## Blue/green deployment

### Overall view

1. Spin new `green` cluster
2. Enable federation on both clusters.
3. Deploy new version of applications to use `green` cluster
  - it requires mq-secret - to be provisioned manually
4. Start federation on the `blue` cluster
5. Ensure that all messages are gone from `blue` cluster
6. Disable `blue` cluster



### Detailed steps done during testing
1. Spin up new cluster in another namespace
2. Enable Federation on both clusters.  
  This doesn't restart clusters
```yaml
    additionalPlugins: [ "rabbitmq_federation", "rabbitmq_federation_management" ]
```

3. Create sample existing exchange/queue on `blue` cluster  
  - one with classic queue on source
Exchange: Concent.Cases.API.Features.Documents:DocumentPublishedIntegrationEvent | fanout | durable

4. Create the queue on the `green` clsuter but using `quorum` type
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
