# Troubleshooting

It is good to verify if any of your issues are in [Troubleshooting documentation](https://www.rabbitmq.com/kubernetes/operator/troubleshooting-operator)


## Why restart of pods takes so much time - 7 days?

Termination Grace Period Timeout is is `604800` - `7 days` [docs](https://www.rabbitmq.com/kubernetes/operator/using-operator#TerminationGracePeriodSeconds).
>TerminationGracePeriodSeconds is the timeout that each rabbitmqcluster pod will have to run the container preStop lifecycle hook to ensure graceful termination. The lifecycle hook checks quorum status of existing quorum queues

On running node we can run this script [check_if_node_is_quorum_critical](https://www.rabbitmq.com/docs/man/rabbitmq-queues.8#check_if_node_is_quorum_critical)
and verify how this node is synced
```bash
rabbitmq-queues check_if_node_is_quorum_critical
```

## How to speed up restart?

In our case closing connections to particular node that is terminating change output logs to this:
```log
rabbitmq <concrete-date> [info] <0.24591.3> queue '<queue-name>' in vhost '<vhost-name>': term mismatch - follower had entry at <number> with term <number> but not with term <number>
rabbitmq <concrete-date> [info] <0.24591.3> Asking leader {'<queue-name>','<one of the server nodes>'} to resend from 307
```

How to do it?

1. Take connections name - running the script from one of the rabbitmq pods:
```bash
rabbitmqadmin list connections
```

2. Make api call running this bash script:
```bash
#!/bin/sh
user=<user-name>
password=<password>
apiUrl="https://<host-of-your-cluster>/api/connections/"
# url need to be encoded so
# for conection with name: 10.244.21.107:35096 -> 10.244.57.6:5672
# curl looks like below
curl --request DELETE -v --user $user:$password --url "${apiUrl}10.244.25.197%3A60474%20-%3E%2010.244.59.7%3A5672"
```

## Pods Are stuck in the Termination state

Here is detailed [docs](https://www.rabbitmq.com/kubernetes/operator/troubleshooting-operator#pods-stuck-in-terminating-state)

## I want to delete one pod and pause a deployment of it

Here is detailed [docs](https://www.rabbitmq.com/kubernetes/operator/troubleshooting-operator#pods-crash-loop)

## My pod is restarting during startup with Mensia timeout

Symptom:
In logs you can find message like below:
>[warning] <0.314.0> Error while waiting for Mnesia tables: {timeout_waiting_for_tables,[rabbit_durable_queue]}
And after 10 retries with 30second timeout pod is restarted. 

Solution:
You can change number of retries and timeout for each retry. 
After restart of the pod you need to be quick :)
Log in using shell to the pod and run commands

```bash
rabbitmqctl eval 'application:set_env(rabbit, mnesia_table_loading_retry_timeout, 60000).'
rabbitmqctl eval 'application:set_env(rabbit, mnesia_table_loading_retry_limit, 20).'
```

## My pod is restarting during startup with Mensia timeout - I am desperate nothing has helped

Please at first ensure that you tried playing with timeuts.

If nothing helped and you are desperate to start a pod without timeout you can use option `force_boot`
Node will start but will be not synchronized with the others.
In our cases it doesn't showed as a cluster node. However pod was working.

Some docs to read in prior:
- [Stack Overflow-  Rabbit mq - Error while waiting for Mnesia tables](https://stackoverflow.com/a/66567321/7255767)

Option to run this comands doesn't work:
```bash
rabbitmqctl stop_app
rabbitmqctl force_boot
```

Solution that work:
After restart you can create `force_load` file in a 
mensia server (e.g. `rabbit@rabbitmq-cluster-server-0.rabbitmq-cluster-nodes.lighthouse`) folder:
```bash
touch /var/lib/rabbitmq/mnesia/rabbit@rabbitmq-cluster-server-0.rabbitmq-cluster-nodes.lighthouse/force_load
```
[Source](https://github.com/helm/charts/issues/13485#issuecomment-493384936)

## How to change loging level

After restart, before rabbit will start you can modify `rabbitmq.conf` file.
All possible options are available in [rabbitmq.conf.example](https://github.com/rabbitmq/rabbitmq-server/blob/main/deps/rabbit/docs/rabbitmq.conf.example)

```bash
echo "log.console.level = debug" >> /etc/rabbitmq/rabbitmq.conf
```
