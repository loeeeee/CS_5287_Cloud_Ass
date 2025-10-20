# Syslog Gatherer and ClamAV Scanner

This directory contains Kubernetes manifests for deploying a syslog-ng collector with ClamAV virus scanning to the k3s cluster, integrated with the existing Kafka infrastructure.

## Architecture Overview

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

### 1. Syslog-ng Collector
- **Deployment**: Single replica with syslog-ng container
- **Service**: NodePort service exposing UDP/TCP 514 (NodePorts 30514/30515)
- **Configuration**: Parses incoming syslog messages and outputs to Kafka `syslog-raw` topic
- **Resources**: 256Mi memory, 100m CPU

### 2. ClamAV Scanner
- **Deployment**: ClamAV daemon + Python scanner application
- **Init Container**: Updates virus definitions on startup
- **Scanner App**: Consumes from `syslog-raw`, scans content, produces to `scan-results`
- **Resources**: 1Gi memory for ClamAV, 256Mi for scanner

### 3. Kafka Connect Integration
- **Sink Connector**: JDBC sink for `scan-results` topic
- **Database**: PostgreSQL `syslog` database with `scan_results` table
- **Schema**: Comprehensive scan results with threat detection metadata

### 4. Code-Server Integration
- **rsyslog**: Configured to forward all logs to k3s syslog-ng collector
- **Target**: alphard (172.22.0.134:30515) via TCP
- **Firewall**: Updated to allow outbound syslog traffic

## Prerequisites

1. **k3s cluster running** (alphard + hamal)
2. **PostgreSQL LXC deployed** (alkaid at 172.22.0.133)
3. **Kafka cluster running** (existing infrastructure)
4. **kubectl configured** to access k3s cluster
5. **Code-server LXC deployed** (alnilam at 172.22.0.130)

## Deployment Instructions

### Step 1: Update PostgreSQL Configuration

First, update and deploy the PostgreSQL configuration to add syslog database:

```bash
cd /home/loe/Documents/IaC
# Deploy PostgreSQL changes
ssh root@172.22.0.133 "nixos-rebuild switch"
```

This will:
- Create `syslog` database and user
- Allow connections from k3s pod network (10.42.0.0/16)
- Set up authentication for syslog user

### Step 2: Update Code-Server Configuration

Deploy code-server changes to enable syslog forwarding:

```bash
# Deploy code-server changes
ssh root@172.22.0.130 "nixos-rebuild switch"
```

This will:
- Install and configure rsyslog
- Forward all logs to k3s syslog-ng collector
- Update firewall rules for outbound syslog traffic

### Step 3: Update K3s Server Firewall

Deploy k3s-server firewall changes:

```bash
# Deploy k3s-server changes
ssh root@172.22.0.134 "nixos-rebuild switch"
```

This will:
- Allow syslog traffic on NodePorts 30514/30515
- Enable access from LAN networks

### Step 4: Deploy Syslog-ng Collector

Deploy the syslog-ng collector:

```bash
# Deploy syslog-ng
kubectl apply -f k8s/syslog-ng/

# Check deployment status
kubectl get pods -l app=syslog-ng
kubectl get svc syslog-ng
```

### Step 5: Build and Deploy ClamAV Scanner

Build the scanner application image:

```bash
# Build scanner image (run on k3s node)
cd /home/loe/Documents/IaC/k8s/clamav-scanner/scanner-app
docker build -t syslog-scanner:latest .

# Deploy ClamAV scanner
kubectl apply -f k8s/clamav-scanner/

# Check deployment status
kubectl get pods -l app=clamav-scanner
```

### Step 6: Create Kafka Connect Sink Connector

Create the PostgreSQL sink connector for scan results:

```bash
# Wait for Kafka Connect to be ready
kubectl wait --for=condition=ready pod -l app=kafka-connect --timeout=300s

# Port forward to access Kafka Connect REST API
kubectl port-forward svc/kafka-connect 8083:8083 &

# Create the connector
curl -X POST -H "Content-Type: application/json" \
  --data @k8s/kafka-connect/syslog-sink-connector.json \
  http://localhost:8083/connectors
```

### Step 7: Test the Pipeline

Run the test script to validate the complete pipeline:

```bash
cd /home/loe/Documents/IaC/scripts
python3 test_syslog_scanner.py
```

## Configuration Details

### Syslog-ng Configuration
- **Listen Ports**: UDP/TCP 514
- **NodePorts**: 30514 (UDP), 30515 (TCP)
- **Kafka Topic**: `syslog-raw`
- **Output Format**: JSON with parsed syslog fields

### ClamAV Scanner Configuration
- **Input Topic**: `syslog-raw`
- **Output Topic**: `scan-results`
- **Scan Patterns**: EICAR, PowerShell, injection attempts, suspicious URLs
- **ClamAV Socket**: `/tmp/clamd.socket`

### PostgreSQL Schema
- **Database**: `syslog`
- **User**: `syslog` (password: `syslog123`)
- **Table**: `scan_results` (auto-created by Kafka Connect)
- **Key Fields**: scan_id, timestamp, source_ip, threat_detected, severity

### Code-Server Syslog Forwarding
- **Target**: 172.22.0.134:30515 (TCP)
- **Format**: RSYSLOG_SyslogProtocol23Format
- **Local Logs**: Also maintained in `/var/log/syslog`

## Verification

### Check Syslog-ng Status

```bash
# Check pods
kubectl get pods -l app=syslog-ng

# Check service
kubectl get svc syslog-ng

# Check logs
kubectl logs -l app=syslog-ng
```

### Check ClamAV Scanner Status

```bash
# Check pods
kubectl get pods -l app=clamav-scanner

# Check ClamAV daemon logs
kubectl logs -l app=clamav-scanner -c clamav-daemon

# Check scanner app logs
kubectl logs -l app=clamav-scanner -c scanner-app
```

### Check Kafka Topics

```bash
# List topics
kubectl exec -it kafka-0 -- kafka-topics --bootstrap-server kafka:9092 --list

# Check syslog-raw topic
kubectl exec -it kafka-0 -- kafka-console-consumer --bootstrap-server kafka:9092 --topic syslog-raw --from-beginning --max-messages 5

# Check scan-results topic
kubectl exec -it kafka-0 -- kafka-console-consumer --bootstrap-server kafka:9092 --topic scan-results --from-beginning --max-messages 5
```

### Check PostgreSQL Data

```bash
# Connect to PostgreSQL
kubectl run postgresql-client --image=postgres:15 --rm -it -- psql -h 172.22.0.133 -U syslog -d syslog

# Query scan results
SELECT scan_id, timestamp, source_host, threat_detected, threat_name, severity 
FROM scan_results 
ORDER BY timestamp DESC 
LIMIT 10;

# Query threat statistics
SELECT threat_detected, severity, COUNT(*) as count
FROM scan_results 
GROUP BY threat_detected, severity
ORDER BY count DESC;
```

## Troubleshooting

### Common Issues

1. **Syslog-ng not receiving messages**
   ```bash
   # Check if NodePort is accessible
   telnet 172.22.0.134 30515
   
   # Check syslog-ng logs
   kubectl logs -l app=syslog-ng
   ```

2. **ClamAV scanner not processing messages**
   ```bash
   # Check if ClamAV daemon is running
   kubectl exec -it deployment/clamav-scanner -c clamav-daemon -- clamdscan --version
   
   # Check scanner app logs
   kubectl logs -l app=clamav-scanner -c scanner-app
   ```

3. **Kafka Connect connector failing**
   ```bash
   # Check connector status
   curl http://localhost:8083/connectors/syslog-scan-results-sink-connector/status
   
   # Check connector logs
   kubectl logs -l app=kafka-connect
   ```

4. **PostgreSQL connection issues**
   ```bash
   # Test connection from k3s pod
   kubectl run test-pod --image=postgres:15 --rm -it -- psql -h 172.22.0.133 -U syslog -d syslog
   ```

### Useful Commands

```bash
# Check all resources
kubectl get all -l app=syslog-ng
kubectl get all -l app=clamav-scanner

# Port forward for debugging
kubectl port-forward svc/syslog-ng 514:514
kubectl port-forward svc/kafka-connect 8083:8083

# Access syslog-ng shell
kubectl exec -it deployment/syslog-ng -- bash

# Access ClamAV scanner shell
kubectl exec -it deployment/clamav-scanner -c scanner-app -- bash
```

## Security Notes

- PostgreSQL credentials are stored in Kubernetes secrets (base64 encoded)
- ClamAV virus definitions are updated on container startup
- Syslog messages are scanned for malicious patterns and content
- Network traffic is restricted by firewall rules
- Consider using TLS for production deployments

## Performance Tuning

For production deployments, consider:

- **Syslog-ng**: Increase replicas, adjust buffer sizes
- **ClamAV**: Scale horizontally, adjust scan timeouts
- **Kafka**: Increase partition count, adjust retention
- **PostgreSQL**: Tune connection pool, add indexes
- **Storage**: Use faster storage classes for ClamAV definitions
