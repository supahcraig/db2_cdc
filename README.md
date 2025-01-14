# db2_cdc
Creates a DB2 instances enabled for CDC, and pushes those CDC events to Redpanda using Kafka Connect.  

## Pre-requisites

You'll want something like an Ubuntu server (version 22 or greater), since the base docker image isn't available for macos.







# Appendix

## Installing Docker on an Ubuntu instance.

https://docs.docker.com/engine/install/ubuntu/

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

Then actually install Docker:

```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get install docker-compose
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


