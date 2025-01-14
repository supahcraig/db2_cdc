# db2_cdc
Creates a DB2 instances enabled for CDC, and pushes those CDC events to Redpanda using Kafka Connect.  

## Pre-requisites

You'll want something like an Ubuntu server (version 22 or greater), since the base docker image isn't available for macos.  I used a c5.xlarge with a 30GB gp3 volume.  The default 8GB volume will not be big enough to build the docker images.

* Docker
* docker-compose
* git (to clone the repo)



## Spin up the Docker environment

Run this to simplify some of the docker commands we're going to be using:

```bash
cd XE
source env.sh
```


Clone this repo into your EC2 instance, and cd into the project directory

```bash
git clone https://github.com/supahcraig/db2_cdc.git
cd db2_cdc
```

Then bring up the docker-compose environment:

```bash
sudo docker-compose up --build
```

OR more simply use the `up` alias which will bring up the compose while simultaneously building the docker images.

```bash
up
```

Similarly `down` will tear down the environment and delete the volumes.

```bash
down
```



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

```

Then actually install Docker:

```bash
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get install -y docker-compose
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


