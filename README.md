# XMR Metrics
Example setup to collect Monero related metrics using bash + InfluxDB and Grafana.

![screenshoot](https://i.imgur.com/oKAvqg9.png)
Demo: [https://monitor.ditatompel.com/d/xmr_metrics/monero-metrics?orgId=2](https://monitor.ditatompel.com/d/xmr_metrics/monero-metrics?orgId=2)

## Prepare the system
In this article, I use :
Ubuntu 18.04 for Grafana and InfluxDB.

### Install Grafana (OSS Version)
If you already have Grafana, you can skip this step. For detailed installation guide on Debian based, please follow [official installation guide](https://grafana.com/docs/grafana/latest/installation/debian/).

Add stable Grafana OSS repository:
```bash
sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget curl
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
```
Install Grafana:
```bash
sudo apt-get update
sudo apt-get install grafana
```

Start Grafana service and make sure service is running (systemd):
```bash
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

To make Grafana server to start at boot:
```bash
sudo systemctl enable grafana-server.service
```

### Install InfluxDB
Add the InfluxData repository:
```bash
echo "deb https://repos.influxdata.com/ubuntu bionic stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
```
Install InfluxDB:
```bash
sudo apt-get update
sudo apt-get install influxdb
```

Start InfluxDB service and make sure service is running (systemd):
```bash
sudo systemctl daemon-reload
sudo systemctl start influxdb
sudo systemctl status influxdb
```
To make InfluxDB server to start at boot:
```bash
sudo systemctl enable influxdb.service
```
#### Configure InfluxDB
Launch InfluxDB’s command line interface (`influx`)
```
influx -precision rfc3339
```
Once you’ve entered the shell and successfully connected to InfluxDB, create at least one InfluxDB admin user:
```
CREATE USER <YOUR_INFLUXDB_ADMIN_USER> WITH PASSWORD '<YOUR_INFLUXDB_ADMIN_PASSWORD>' WITH ALL PRIVILEGES
```
> Change `<YOUR_INFLUXDB_ADMIN_USER>` and `<YOUR_INFLUXDB_ADMIN_PASSWORD>` with your desired username and password

Create database to store Monero Metrics:
```
CREATE DATABASE MoneroMetrics
```
Create non-admin user (for Grafana and bash script we use latter) and grant privileges to `MoneroMetrics` database:
```
CREATE USER grafana WITH PASSWORD 'some_password'
GRANT READ ON MoneroMetrics TO grafana

CREATE USER monero WITH PASSWORD 'some_password'
GRANT ALL ON MoneroMetrics TO monero
```

Enable authentication in your configuration file (`/etc/influxdb/influxdb.conf`) by setting the `auth-enabled` option to `true` in the `[http]` section:

> **Note**: You might also need to disable queue limit and timeout by setting the `max-enqueued-write-limit` and `enqueued-write-timeout` to `0` in the `[http]` section.

Restart InfluxDB service
```bash
systemctl restart influxdb
```

## Collect and storing metrics
In this article, there are 4 types of metric we will collect and store it to InfluxDB:
* Node metrics via `monerod` RPC ([NodeMetrics.sh](examples/bash/NodeMetrics.sh))
* XMRig worker metrics ([XmrigMetrics.sh](examples/bash/XmrigMetrics.sh))
* Pool metrics ([PoolMetrics.sh](examples/bash/PoolMetrics.sh))
* Exchange metrics ([IndodaxExchange.sh](examples/bash/PoolMetrics.sh))

You can find all example files under [examples](examples) directory.

All script written in bash, `jq` package is required to run all of these script. In additional, and `bc` package is required to run `PoolMetrics.sh`.

Make sure all bash script is executable and run them using cron job.

### Node metrics
File: [examples/bash/NodeMetrics.sh](examples/bash/NodeMetrics.sh)

If you run local or public Monero node, you can scrap `monerod` metrics using its `rpc` or `restricted-rpc`.
Restrict RPC is view only commands and do not return privacy sensitive data in RPC calls. So, some data like `*_connections_count`, `*_peerlist_size` will return `0`.


### XMRig worker metrics  
File: [examples/bash/XmrigMetrics.sh](examples/bash/XmrigMetrics.sh)

In order to grab XMRig worker metrics, we need to enable XMRig HTTP API for each your XMRig devices. Eg:
```
{
    "api": {
        "id": null,
        "worker-id": null
    },
    "http": {
        "enabled": true,
        "host": "i.i.i.i",
        "port": 54321,
        "access-token": "your password",
        "restricted": true
    },
    ...
```


### Pool metrics  
File: [examples/bash/PoolMetrics.sh](examples/bash/PoolMetrics.sh)

For now, only mining pool who use [jtgrassie/monero-pool](https://github.com/jtgrassie/monero-pool) and [Snipa22/nodejs-pool](https://github.com/Snipa22/nodejs-pool) backend is supported. Feel free to edit the script and add your favorite mining pool backend.

it's quite easy to find pool backend and usually each frontend design quite similar. For example: monerop.com, xmrvsbeast.com using jtgrassie and moneroocean.stream, moneromine.co using snipa22.

**Important About Pool Metrics**:   

You may doesn't need to grab *Network Difficulty* and *Network Height* data from your mining pool server, especially those who use nodejs-pool by Snipa22. This because we need to fetch  one additional API request to the server and may cause DOS effect on high traffic pool.

Avoid doing that by comment out `NetworkInfo=$(curl -s ${POOLPARAMS[1]}/network/stats ...` and remove `NetDiff=$NetworkDiff` and `NetHeight=$NetworkHeight` InfluxDB data post. Eg:
```bash
curl -i -XPOST 'http://192.168.100.1:8086/write?db=MoneroMetrics' -u monero:some_password --data-binary "PoolInfo,Node=${POOLPARAMS[0]} PoolHR=$PoolHR,RoundHR=$RoundHashes,LastBlock=$LastBlockFound,BlockFound=$PoolBlockFound,CountMiners=$ConnectedMiners,MyHashrate=$MinerHashrate,MyBalance=$MinerBalance"
```

### Coin Exchange metrics
File: [examples/bash/IndodaxExchange.sh](examples/bash/IndodaxExchange.sh)

If you like to add coin price, market, etc, you can use your favorite exchange API. In this example, I use Indodax API as my local currency exchange. You may create your own script to do that. Some exchange like [Kraken provide an example API client](https://www.kraken.com/features/api#example-api-code) too.  


## Create the dashboard
After all data is collected, lets create the Grafana dashboard. We need to add our InfluxDB data source first.
Login to Grafana > `Configuration` > `Data Sources` > `Add Data Source` and choose `InfluxDB`.
Leave Query Language to default (`InfluxQL`)

In the `HTTP` section, fill `URL` to your InfluxDB server.

In `InfluxDB` Details section, fill your database access details:

Database: `MoneroMetrics`   
User: `grafana`   
Password: `your_configured_password`   

![InfluxDB example setting](https://i.imgur.com/NsyVyTM.png)

Save and Test.

Now you can create your Monero dashboard. You may export my dashboard template from the [demo site](https://monitor.ditatompel.com/d/xmr_metrics/monero-metrics?orgId=2) by clicking share icon.

![grafana share button](https://i.imgur.com/b706cBe.png)

> **Note**: In order to use my dashboard, you may need to install [Blendstat panel plugin](https://grafana.com/grafana/plugins/farski-blendstat-panel/).

## Resources and Credits
* [Grafana Installation](https://grafana.com/docs/grafana/latest/installation/) (Grafana Docs)
* [Install InfluxDB on Ubuntu 20.04/18.04 and Debian 9](https://computingforgeeks.com/install-influxdb-on-ubuntu-and-debian/) by
[Josphat Mutai](https://computingforgeeks.com/author/mutai-josphat/)
* [Authentication and authorization in InfluxDB](https://docs.influxdata.com/influxdb/v1.8/administration/authentication_and_authorization/) (InfluxDB Docs)
* [Using InfluxDB in Grafana](https://grafana.com/docs/grafana/latest/datasources/influxdb/) (Grafana Docs)
* [Create Fancy Graph with metrics from XMRIG (1/3)](https://ecency.com/monero/@master-lamps/create-fancy-graph-with-metrics-from-xmrig-1-3) by [master-lamps](https://ecency.com/@master-lamps)
* [Create Fancy Graph with metrics from XMRIG (2/3)](https://ecency.com/monero/@master-lamps/create-fancy-graph-with-metrics-from-xmrig-2-3) by [master-lamps](https://ecency.com/@master-lamps)
* [Create Fancy Graph with metrics from XMRIG (3/3)](https://ecency.com/monero/@master-lamps/create-fancy-graph-with-metrics-from-xmrig-3-3) by [master-lamps](https://ecency.com/@master-lamps)

If you want to create data scraping using your desired programming language, feel free to create a pull request.
