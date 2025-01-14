# Creating a CDC pipeline from DB2 using Kafka Connect/Debezium

This walkthorugh will creates a DB2 instance enabled for CDC, a Redpanda single-node "cluster" to recieve the CDC events, and a Kafka Connect container running Debezium to consume CDC events from the source database and push them to Redpanda, plus a few other helpful containers.


## Pre-requisites

You'll want something like an Ubuntu server (version 22 or greater), since the base docker image isn't available for macos.  I used a c5.xlarge with a 30GB gp3 volume.  The default 8GB volume will not be big enough to build the docker images.  You'll need your security group open on port `22` for SSH and `8080` for access to the Redpanda Console.  If you want to use remote SQL client to connect to the db2 instance (personal preference:  dBeaver), you'll also need to be open on port `50000`.   This is not required, the dabase can be accessed direcly from the command line if you prefer.

* Docker
* docker-compose
* git (to clone this repository)


## Spin up the Docker environment

Clone this repo into your EC2 instance, and cd into the project directory

```bash
git clone https://github.com/supahcraig/db2_cdc.git
cd db2_cdc
```

Run this to simplify some of the docker commands we're going to be using:

```bash
source env.sh
```


Then bring up the docker-compose environment using the `up` alias (which is really just `docker-compose up --build -V`), which will build the db2 & debezium docker images on the fly.

```bash
up
```

Similarly `down` will tear down the environment and delete the volumes.

```bash
down
```

## Verify the Components

### Verify DB2

From a new terminal window...

1.  Drop into the db2server container shell:  `docker exec -it db2server /bin/bash`
2.  Switch to the db2inst1 user:  `su - db2inst1`
3.  Connect to your testdb database:  `db2 connect to testdb user db2inst1 using password`
4.  Run a simple query on one of the sample tables:  `SELECT * FROM CUSTOMERS`

You should see 4 rows:

```
ID        FIRST_NAME            LAST_NAME             EMAIL
--------- --------------------- --------------------- -----------------------------
     1001 Sally                 Thomas                 sally.thomas@acme.com
     1002 George                Bailey                 gbailey@foobar.com
     1003 Edward                Walker                 ed@walker.com
     1004 Anne                  Kretchmar              annek@noanswer.org

  4 record(s) selected.
```

### Verify Redpanda/Kafka Connect

1.  Navigate to `http://your-docker-host:8080` to bring up the Redpanda Console.
2.  On the Overview tab, you should see a green check next to the lone broker in the BROKER DETAILS section
3.  On the Connectors tab, navigate to Kafka Connect
4.  Under Clusters you should see `DebeziumConnect`
5.  Clicking on the Connectors sub-tab, you should see the `inventory-connector` connector.  Click on it.
6.  It should have a green check and say Running, but it might not.
7.  If it is failed, simply click the restart button (ignore any alerts about permissions)
8.  It should now say Running.
9.  Navigating back to the Topic tab, you should now see 4 topics prefixed with `db2server.DB2INST1`.  This is where the CDC events are stored for each source table.


## Take CDC for a spin

Again from your DB2 shell...

1.  If you're still in the db2 console (i.e. you see the `db2 => ` prompt) type  `quit` to return to the shell prompt
2.  Execute a series of insert statements: `db2 -tvf insert.sql`, which should return output like this:

```sql
INSERT INTO DB2INST1.CUSTOMERS (FIRST_name, last_name, email) VALUES ('Robert', 'Plant', 'feather@zep.com')
DB20000I  The SQL command completed successfully.

INSERT INTO DB2INST1.CUSTOMERS (FIRST_name, last_name, email) VALUES ('Jimmy', 'Page', 'zoso@zep.com')
DB20000I  The SQL command completed successfully.

INSERT INTO DB2INST1.CUSTOMERS (FIRST_name, last_name, email) VALUES ('John Paul', 'Jones', 'celtic@zep.com')
DB20000I  The SQL command completed successfully.

INSERT INTO DB2INST1.CUSTOMERS (FIRST_name, last_name, email) VALUES ('John', 'Bonham', 'circles@zep.com')
DB20000I  The SQL command completed successfully.
```

Now go back to the Redpanda Console...

1.  Navigate to the Topic tab
2.  Click into `db2server.DB2INST1.CUSTOMERS`
3.  You should see 8 messages, with the latest 4 being the rows we just inserted.
4.  Drill into any of them to see the CDC payload, with the schema, before record, after record, and lots of metadata about the event.

```json
{
    "schema": {
        "type": "struct",
        "fields": [
            {
                "type": "struct",
                "fields": [
                    {
                        "type": "int32",
                        "optional": false,
                        "field": "ID"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "FIRST_NAME"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "LAST_NAME"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "EMAIL"
                    }
                ],
                "optional": true,
                "name": "db2server.DB2INST1.CUSTOMERS.Value",
                "field": "before"
            },
            {
                "type": "struct",
                "fields": [
                    {
                        "type": "int32",
                        "optional": false,
                        "field": "ID"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "FIRST_NAME"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "LAST_NAME"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "EMAIL"
                    }
                ],
                "optional": true,
                "name": "db2server.DB2INST1.CUSTOMERS.Value",
                "field": "after"
            },
            {
                "type": "struct",
                "fields": [
                    {
                        "type": "string",
                        "optional": false,
                        "field": "version"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "connector"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "name"
                    },
                    {
                        "type": "int64",
                        "optional": false,
                        "field": "ts_ms"
                    },
                    {
                        "type": "string",
                        "optional": true,
                        "name": "io.debezium.data.Enum",
                        "version": 1,
                        "parameters": {
                            "allowed": "true,last,false,incremental"
                        },
                        "default": "false",
                        "field": "snapshot"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "db"
                    },
                    {
                        "type": "string",
                        "optional": true,
                        "field": "sequence"
                    },
                    {
                        "type": "int64",
                        "optional": true,
                        "field": "ts_us"
                    },
                    {
                        "type": "int64",
                        "optional": true,
                        "field": "ts_ns"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "schema"
                    },
                    {
                        "type": "string",
                        "optional": false,
                        "field": "table"
                    },
                    {
                        "type": "string",
                        "optional": true,
                        "field": "change_lsn"
                    },
                    {
                        "type": "string",
                        "optional": true,
                        "field": "commit_lsn"
                    }
                ],
                "optional": false,
                "name": "io.debezium.connector.db2.Source",
                "field": "source"
            },
            {
                "type": "string",
                "optional": false,
                "field": "op"
            },
            {
                "type": "int64",
                "optional": true,
                "field": "ts_ms"
            },
            {
                "type": "int64",
                "optional": true,
                "field": "ts_us"
            },
            {
                "type": "int64",
                "optional": true,
                "field": "ts_ns"
            },
            {
                "type": "struct",
                "fields": [
                    {
                        "type": "string",
                        "optional": false,
                        "field": "id"
                    },
                    {
                        "type": "int64",
                        "optional": false,
                        "field": "total_order"
                    },
                    {
                        "type": "int64",
                        "optional": false,
                        "field": "data_collection_order"
                    }
                ],
                "optional": true,
                "name": "event.block",
                "version": 1,
                "field": "transaction"
            }
        ],
        "optional": false,
        "name": "db2server.DB2INST1.CUSTOMERS.Envelope",
        "version": 2
    },
    "payload": {
        "before": null,
        "after": {
            "ID": 1006,
            "FIRST_NAME": "Jimmy",
            "LAST_NAME": "Page",
            "EMAIL": "zoso@zep.com"
        },
        "source": {
            "version": "2.6.2.Final",
            "connector": "db2",
            "name": "db2server",
            "ts_ms": 1736898381548,
            "snapshot": "false",
            "db": "TESTDB",
            "sequence": null,
            "ts_us": 1736898381548533,
            "ts_ns": 1736898381548533000,
            "schema": "DB2INST1",
            "table": "CUSTOMERS",
            "change_lsn": "00000000:00000000:000000000446140f",
            "commit_lsn": "00000000:00001e36:000000000004a1b4"
        },
        "op": "c",
        "ts_ms": 1736898381548,
        "ts_us": 1736898381548812,
        "ts_ns": 1736898381548812500,
        "transaction": null
    }
}
```






---

# Appendix

## Installing Docker on an Ubuntu instance.

https://docs.docker.com/engine/install/ubuntu/

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get install -y docker-compose

sudo usermod -aG docker ubuntu
newgrp docker
```


---

# Troubleshooting

## No Match for Platform in Manifest

If you get this sort of error, you're probably trying to deploy this on your mac, but there isn't a docker image for mac for DB2.   I used Ubuntu 24 on EC2, but RHEL should also be suitable.   

```bash
=> [db2server internal] load build definition from Dockerfile  
 => => transferring dockerfile: 805B        
 => ERROR [db2server internal] load metadata for docker.io/ibmcom/db2:11.5.4.0      
 => [db2server auth] ibmcom/db2:pull token for registry-1.docker.io          
------
 > [db2server internal] load metadata for docker.io/ibmcom/db2:11.5.4.0:
------
failed to solve: ibmcom/db2:11.5.4.0: failed to resolve source metadata for docker.io/ibmcom/db2:11.5.4.0: no match for platform in manifest: not found
```


