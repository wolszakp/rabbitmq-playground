# Rabbitmq playground

## Performance tests

https://github.com/rabbitmq/rabbitmq-perf-test?tab=readme-ov-file

docker run -it --rm pivotalrabbitmq/perf-test:latest --help

```bash
docker network create perf-test
docker run -it --rm --network perf-test --name rabbitmq -p 15672:15672 rabbitmq:3.8.2-management
docker run -it --rm --network perf-test pivotalrabbitmq/perf-test:latest --uri amqp://rabbitmq
```



### 3.13.0

With limiting memory and CPU:
```bash
docker run -it --rm --cpus="0.5" --memory="1g" --network perf-test --name rabbitmq -p 15672:15672 rabbitmq:3.13.0-management
```

#### Test for classic queue
docker run -it --rm --network perf-test pivotalrabbitmq/perf-test:latest --uri amqp://rabbitmq --producers 1 --consumers 2 --autoack --size 1000 --queue classic-test --auto-delete true --time 20

```bash
id: test-135806-165, sending rate avg: 20865 msg/s
id: test-135806-165, receiving rate avg: 20846 msg/s
id: test-135806-165, consumer latency min/median/75th/95th/99th 443/339217/382721/422546/488634 µs
```

#### Test for quorum queue
docker run -it --rm --network perf-test pivotalrabbitmq/perf-test:latest --uri amqp://rabbitmq --producers 1 --consumers 2 --autoack --size 1000 --quorum-queue --queue quorum-test --auto-delete false --time 20

```bash
id: test-135909-302, sending rate avg: 13456 msg/s
id: test-135909-302, receiving rate avg: 13439 msg/s
id: test-135909-302, consumer latency min/median/75th/95th/99th 10275/627933/674754/702491/717368 µs
```



### 3.8.19

With limiting memory and CPU:
```
docker run -it --rm --cpus="0.5" --memory="1g" --network perf-test --name rabbitmq -p 15672:15672 rabbitmq:3.8.19-management
```

#### Test for classic queue

```bash
id: test-135505-333, sending rate avg: 38971 msg/s
id: test-135505-333, receiving rate avg: 38971 msg/s
id: test-135505-333, consumer latency min/median/75th/95th/99th 1099/161874/175821/183267/189169 µs
```

#### Test for quorum queue
```bash
id: test-135534-374, sending rate avg: 10346 msg/s
id: test-135534-374, receiving rate avg: 10079 msg/s
id: test-135534-374, consumer latency min/median/75th/95th/99th 37664/422655/464396/493848/1437912 µs
```

## Queueus

- Queues always keep parto of messages in memory
- Queue is an Erlang process  
  Has its own heap (security & reliability)
- Body is stored separately in a seprate memory  
  Body of the message is stored in `Binaries` (shared across different processes)  
  When message is stored in multiple queues then body of it is stored only once. 
  Headers and properties are copied across queues.
- Service booting  
  When RabbitMQ starts, up to 15384 messages smaller than 4k are loaded into memory per queue
- Lazy queues  
  Memory over throughput (When memory is more important than throughput)
  Consumers are slow (Queueues grow and consume more memory than needed) 
  Apply lazy mode on dead letter queues  (error quques)


## Configuration

-`rabbitmq.conf` file 
[rabbitmq.conf.example](https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/rabbitmq.conf.example)
in config it is named without extension. File however need that extension.
- `heartbeat` (default 60s)
https://www.rabbitmq.com/docs/heartbeats#heartbeats-timeout
- `frame_max` (default 131072 bytes) 
Set the max permissible size of an AMQP frame (in bytes).
https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/rabbitmq.conf.example
Larger value improves ghroughtput, smaller value improves latency (not related with max message size which is 2GB)


## Tunning

- `queue_index_embed_msgs_below`, -> half of the default message size (default 4096)
From node:
rabbitmq-diagnostics environment | grep queue_index -A 10

- `collect_statistics_interval` - more rarely e.g. 30 seconds ,(15000- currently)

- `rates_mode` - set to `none` (already we have that)

- `frame_max` (default 311072 bytes)  

## RabbitMQ form operator

https://www.rabbitmq.com/kubernetes/operator/configure-operator-defaults

- Messaging topology operator
https://github.com/rabbitmq/messaging-topology-operator/releases
Current version: v1.11.0
Can update to latest: v1.13.0, v1.12.2, v1.12.1, v1.12.0, v1.11.0

- Cluster operator
https://github.com/rabbitmq/cluster-operator

Current: 1.8.1

| From | To  | Notes |
| ---- | --- | --- |
| 1.8.1 | 1.8.2, 1.8.3, | Non cluster changes, default rmq 3.8.21 |
| 1.8.3 | 1.9.0 | will upgrade the cluster |
| 1.9.0 | 1.10.0 | Non cluster changes |
| 1.10.0 | 1.11.0, 1.11.1 | will upgrade the cluster |
| 1.11.1 | 1.12.0, 1.12.1 | Non cluster changes, default rmq 3.9.12 |
| 1.12.1 | 1.13.0, 1.13.1 | Non cluster changes, default rmq 3.10.2 |
| 1.13.1 | 1.14.0 | Non cluster changes |
| 1.14.0 | 2.0.0 | BREAKING, requires rmq 3.9.9 or up, will upgrade the cluster |
| 2.0.0 | 2.1.0 | Will upgrade the cluster |
| 2.1.0 | 2.2.0, 2.3.0 | Non cluster changes, default rmq 3.11.18 |
| 2.3.0 | 2.4.0 | BREAKING, use rmq 3.12.2 by default, please make sure: </br> - You currently run 3.11.18 </br> - All feature flags are enabled (rabbitmqctl list_feature_flags, rabbitmqctl enable_feature_flag all) <br/> - Verify https://www.rabbitmq.com/upgrade.html |
| 2.4.0 | 2.5.0, 2.6.0, 2.7.0 | Non cluster changes |
| 2.7.0 | 2.8.0 | Non cluster changes, default rmq 3.13 |


