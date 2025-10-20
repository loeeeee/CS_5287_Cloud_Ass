# Kafka K3s Integration

This directory contains Kubernetes manifests for deploying Apache Kafka to the k3s cluster with PostgreSQL integration via Kafka Connect.

## Architecture Overview

### Kafka Integration
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Demo Producer │───▶│   Kafka (k3s)   │───▶│ Kafka Connect   │
│   (k3s Job)     │    │                 │    │ JDBC Sink       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                               ┌─────────────────┐
                                               │  PostgreSQL     │
                                               │  (alkaid LXC)   │
                                               │  172.22.0.133   │
                                               └─────────────────┘
```

### Syslog ClamAV Scanner
```
External Network     K3s Cluster                     PostgreSQL
  Devices                                            (alkaid)
     │                                              172.22.0.133
     │  UDP/TCP 514
     ▼
┌─────────────┐
│  syslog-ng  │──────▶ syslog-raw topic
│ (Deployment)│           │
└─────────────┘           │
     (Service)            ▼
   NodePort 514     ┌──────────┐      ┌──────────────┐
                    │  Kafka   │      │   ClamAV     │
                    │  Broker  │◀────▶│   Scanner    │
                    └──────────┘      │ (Deployment) │
                          │           └──────────────┘
                          │                  │
                          ▼                  ▼
                    syslog-scanned     scan-results
                        topic              topic
                          │                  │
                          └────────┬─────────┘
                                   ▼
                          ┌──────────────────┐
                          │  Kafka Connect   │
                          │   JDBC Sink      │
                          └──────────────────┘
                                   │
                                   ▼
                          ┌──────────────────┐
                          │   PostgreSQL     │
                          │ - syslog_raw     │
                          │ - scan_results   │
                          └──────────────────┘
```

## Components

### 1. Kafka Cluster
- **Zookeeper**: StatefulSet with 1 replica, local-path storage
- **Kafka**: StatefulSet with 1 replica, local-path storage
- **Services**: ClusterIP services for internal communication

### 2. Kafka Connect
- **Deployment**: Single replica with JDBC sink connector
- **Plugins**: Confluent JDBC connector and JSON schema converter
- **Configuration**: Connects to PostgreSQL at 172.22.0.133

### 3. Demo Producer
- **Job**: Produces sample messages to `demo-messages` topic
- **Messages**: JSON format with message_id, timestamp, content, sequence

### 4. PostgreSQL Integration
- **Database**: `kafka` database with `kafka` user
- **Table**: `kafka_messages` (auto-created by Kafka Connect)
- **Network**: Accessible from k3s pod network (10.42.0.0/16)

## Prerequisites

1. **k3s cluster running** (alphard + hamal + mizar)
2. **PostgreSQL LXC deployed** (alkaid at 172.22.0.133)
3. **kubectl configured** to access k3s cluster
4. **Python 3.x** with pip for query script

## Deployment Instructions

### Step 1: Deploy PostgreSQL Configuration

First, update and deploy the PostgreSQL configuration to allow k3s access:

```bash
cd /home/loe/Documents/IaC
./deploy.sh
```

This will:
- Update PostgreSQL to listen on k3s pod network
- Create `kafka` database and user
- Update firewall rules to allow k3s connections

### Step 2: Deploy Kafka Cluster

Deploy Zookeeper and Kafka:

```bash
# Deploy Zookeeper
kubectl apply -f k8s/kafka/zookeeper-statefulset.yaml

# Deploy Kafka
kubectl apply -f k8s/kafka/kafka-statefulset.yaml

# Deploy Services
kubectl apply -f k8s/kafka/services.yaml
```

Wait for pods to be ready:

```bash
kubectl get pods -w
```

### Step 3: Deploy Kafka Connect

Deploy Kafka Connect with JDBC sink plugin:

```bash
# Deploy Kafka Connect
kubectl apply -f k8s/kafka-connect/deployment.yaml

# Deploy Service
kubectl apply -f k8s/kafka-connect/service.yaml

# Deploy Secret (PostgreSQL credentials)
kubectl apply -f k8s/kafka-connect/secret.yaml
```

Wait for Kafka Connect to be ready:

```bash
kubectl get pods -l app=kafka-connect
```

### Step 4: Create JDBC Sink Connector

Create the PostgreSQL sink connector:

```bash
# Wait for Kafka Connect to be ready
kubectl wait --for=condition=ready pod -l app=kafka-connect --timeout=300s

# Create the connector
curl -X POST -H "Content-Type: application/json" \
  --data @k8s/kafka-connect/connector.json \
  http://localhost:8083/connectors
```

Or port-forward and create connector:

```bash
# Port forward to access Kafka Connect REST API
kubectl port-forward svc/kafka-connect 8083:8083 &

# Create connector
curl -X POST -H "Content-Type: application/json" \
  --data @k8s/kafka-connect/connector.json \
  http://localhost:8083/connectors
```

### Step 5: Run Demo Producer

Produce sample messages:

```bash
kubectl apply -f k8s/demo/producer-job.yaml
```

Monitor the job:

```bash
kubectl get jobs
kubectl logs job/kafka-producer-demo
```

### Step 6: Query Messages

Install Python dependencies and run the query script:

```bash
cd /home/loe/Documents/IaC/scripts
pip install -r requirements.txt
python3 query_kafka_messages.py
```

## Verification

### Check Kafka Cluster Status

```bash
# Check pods
kubectl get pods

# Check services
kubectl get svc

# Check topics
kubectl exec -it kafka-0 -- kafka-topics --bootstrap-server kafka:9092 --list
```

### Check Kafka Connect Status

```bash
# Check connector status
curl http://localhost:8083/connectors

# Check connector details
curl http://localhost:8083/connectors/postgresql-sink-connector/status
```

### Check PostgreSQL Data

```bash
# Connect to PostgreSQL
kubectl exec -it postgresql-pod -- psql -U kafka -d kafka

# Query messages
SELECT * FROM kafka_messages ORDER BY processed_at DESC LIMIT 10;
```

## Configuration Details

### Kafka Configuration
- **Bootstrap Servers**: `kafka:9092`
- **Advertised Listeners**: `PLAINTEXT://kafka:9092`
- **Auto Topic Creation**: Enabled
- **Replication Factor**: 1 (single node)
- **Partitions**: 3 (default)

### Kafka Connect Configuration
- **Bootstrap Servers**: `kafka:9092`
- **REST API**: Port 8083
- **Key Converter**: StringConverter
- **Value Converter**: JsonConverter (schemas disabled)
- **JDBC URL**: `jdbc:postgresql://172.22.0.133:5432/kafka`

### PostgreSQL Configuration
- **Host**: 172.22.0.133
- **Port**: 5432
- **Database**: kafka
- **User**: kafka
- **Password**: kafka123
- **Table**: kafka_messages (auto-created)

## Troubleshooting

### Common Issues

1. **Kafka pods not starting**
   ```bash
   kubectl describe pod kafka-0
   kubectl logs kafka-0
   ```

2. **Kafka Connect not connecting to Kafka**
   ```bash
   kubectl logs deployment/kafka-connect
   # Check CONNECT_BOOTSTRAP_SERVERS environment variable
   ```

3. **JDBC connector failing**
   ```bash
   curl http://localhost:8083/connectors/postgresql-sink-connector/status
   # Check PostgreSQL connectivity from k3s pods
   ```

4. **PostgreSQL connection refused**
   ```bash
   # Check if PostgreSQL is accessible from k3s
   kubectl run test-pod --image=postgres:15 --rm -it -- psql -h 172.22.0.133 -U kafka -d kafka
   ```

### Useful Commands

```bash
# Check all resources
kubectl get all

# Check persistent volumes
kubectl get pv,pvc

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Port forward for debugging
kubectl port-forward svc/kafka 9092:9092
kubectl port-forward svc/kafka-connect 8083:8083

# Access Kafka shell
kubectl exec -it kafka-0 -- bash

# List topics
kubectl exec -it kafka-0 -- kafka-topics --bootstrap-server kafka:9092 --list

# Consume messages
kubectl exec -it kafka-0 -- kafka-console-consumer --bootstrap-server kafka:9092 --topic demo-messages --from-beginning
```

## Cleanup

To remove all resources:

```bash
# Delete demo job
kubectl delete job kafka-producer-demo

# Delete connector
curl -X DELETE http://localhost:8083/connectors/postgresql-sink-connector

# Delete Kafka Connect
kubectl delete -f k8s/kafka-connect/

# Delete Kafka cluster
kubectl delete -f k8s/kafka/

# Clean up persistent volumes (optional)
kubectl delete pvc --all
```

## Security Notes

- PostgreSQL credentials are stored in Kubernetes secrets (base64 encoded)
- In production, use proper secret management (e.g., external-secrets, vault)
- Consider using TLS for Kafka and PostgreSQL connections
- Implement proper RBAC for Kubernetes resources
- Use network policies to restrict pod-to-pod communication

## Performance Tuning

For production deployments, consider:

- **Kafka**: Increase replicas, adjust partition count, tune JVM settings
- **Kafka Connect**: Scale horizontally, adjust task count
- **PostgreSQL**: Tune connection pool, indexing, and query optimization
- **Storage**: Use faster storage classes, adjust retention policies
- **Networking**: Use dedicated network interfaces for better throughput
