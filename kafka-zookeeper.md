Installing Apache Kafka and ZooKeeper on Ubuntu 24.04
This guide provides a step-by-step procedure for installing and configuring a single-node Apache Kafka and ZooKeeper instance on an Ubuntu 24.04 server. We will configure them to run as systemd services for easier management.

Step 1: Install Prerequisites (Java)
Apache Kafka is built on the Java Virtual Machine (JVM), so it requires a Java Development Kit (JDK) to run.

Update your package index:

sudo apt update

Install the OpenJDK package: We'll use the default version available in Ubuntu's repositories.

sudo apt install default-jdk -y

Verify the installation: Check the Java version to ensure it was installed correctly.

java -version

You should see output confirming the OpenJDK version.

Step 2: Create a Dedicated Kafka User
For security purposes, it's best to run Kafka using a dedicated, unprivileged user.

Create the kafka user: This command creates a system user named kafka with a home directory at /opt/kafka and no login shell.

sudo useradd -r -m -d /opt/kafka -s /bin/false kafka

Step 3: Download and Extract Kafka
We will now download the Kafka binaries from the official Apache website and place them in the user's home directory.

Navigate to a temporary directory:

cd /tmp

Download the Kafka binaries: Visit the Apache Kafka downloads page to find the latest version. As of this writing, a recent stable version is 3.7.0.

wget [https://downloads.apache.org/kafka/3.7.0/kafka_2.13-3.7.0.tgz](https://downloads.apache.org/kafka/3.7.0/kafka_2.13-3.7.0.tgz)

Extract the archive: We'll extract the contents directly into the /opt/kafka directory. The --strip-components=1 flag removes the top-level directory from the archive.

sudo tar -xzf kafka_2.13-3.7.0.tgz -C /opt/kafka --strip-components=1

Set correct ownership: Ensure the kafka user owns all the files.

sudo chown -R kafka:kafka /opt/kafka

Step 4: Configure Kafka and ZooKeeper
Now, we will create dedicated data directories and update the configuration files.

Create data directories: It's good practice to store data outside of the main application directory.

sudo mkdir -p /var/lib/zookeeper
sudo mkdir -p /var/lib/kafka

Set ownership for data directories:

sudo chown -R kafka:kafka /var/lib/zookeeper
sudo chown -R kafka:kafka /var/lib/kafka

Configure ZooKeeper: Edit the ZooKeeper properties file.

sudo nano /opt/kafka/config/zookeeper.properties

Find the dataDir line and change it to point to the new data directory:

dataDir=/var/lib/zookeeper

Save and close the file.

Configure Kafka: Edit the Kafka server properties file.

sudo nano /opt/kafka/config/server.properties

Find the log.dirs line and change it to point to the new Kafka data directory:

log.dirs=/var/lib/kafka

Save and close the file.

Step 5: Create Systemd Service Files
Creating systemd unit files allows you to manage ZooKeeper and Kafka as services, making it easy to start, stop, and enable them on boot.

Create the ZooKeeper service file:

sudo nano /etc/systemd/system/zookeeper.service

Paste the following content into the file:

[Unit]
Description=Apache ZooKeeper Server
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
Group=kafka
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target

Save and close the file.

Create the Kafka service file:

sudo nano /etc/systemd/system/kafka.service

Paste the following content. Note that this service requires zookeeper.service to be running first.

[Unit]
Description=Apache Kafka Server
Documentation=[http://kafka.apache.org/documentation.html](http://kafka.apache.org/documentation.html)
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
Group=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target

Save and close the file.

Step 6: Start and Enable Services
With the service files created, you can now start the services and enable them to launch automatically on boot.

Reload the systemd daemon:

sudo systemctl daemon-reload

Start ZooKeeper and Kafka:

sudo systemctl start zookeeper
sudo systemctl start kafka

Enable the services to start on boot:

sudo systemctl enable zookeeper
sudo systemctl enable kafka

Check the status of the services:

sudo systemctl status zookeeper
sudo systemctl status kafka

Both should show active (running).

Step 7: Test Your Kafka Installation
Finally, let's confirm that Kafka is working correctly by creating a topic, sending a message, and reading it back.

Create a topic: Create a topic named testTopic.

/opt/kafka/bin/kafka-topics.sh --create --topic testTopic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

Start a console producer: Open a new terminal session and run the producer to send messages to the topic.

/opt/kafka/bin/kafka-console-producer.sh --topic testTopic --bootstrap-server localhost:9092

Type a few messages, pressing Enter after each one:

>Hello Kafka
>This is a test message.

You can press Ctrl+C to exit the producer.

Start a console consumer: Open another terminal session and run the consumer to read the messages. The --from-beginning flag ensures you read all messages in the topic's log.

/opt/kafka/bin/kafka-console-consumer.sh --topic testTopic --from-beginning --bootstrap-server localhost:9092

You should see the messages you sent appear in the console:

Hello Kafka
This is a test message.

This confirms your Kafka installation is working correctly.