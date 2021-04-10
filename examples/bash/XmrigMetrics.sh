#!/bin/bash
# XmrigMetrics.sh
#
# This script used to fetch XMRig metrics via HTTP API request and store it to
# InfluxDB..
# You need to enable your XMRig HTTP API and set your access token.
# See https://xmrig.com/docs/miner/config/api#http-enabled for more details.

# Store each API starting Starting point to $MinerHosts variable
# Eg:
MinerHosts=(
    "http://192.168.1.5:54321"  # 1st rig
    "http://192.168.1.20:12345" # 2nd rig
    "https://example.com/path"  # maybe with https using reverse proxy, etc
)

for worker in "${MinerHosts[@]}"
do
    # You can start conditional if your XMRig access-token is diffrent
    if [[ $worker == 'http://192.168.1.5:54321' ]]
    then
        AuthPass="some_password"
    elif [[ $worker == 'https://example.com/path' ]]
    then
        AuthPass="other_different_password"
    else
        AuthPass="your_xmrig_default_password"
    fi

    MinerStats=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $AuthPass" $worker/1/summary)

    HashRate=$(echo $MinerStats | jq -r '.hashrate.total[0]')
    Miner=$(echo $MinerStats | jq -r '.worker_id')
    Algo=$(echo $MinerStats | jq -r '.algo')
    UpTime=$(echo $MinerStats | jq -r '.uptime')

    # Debug: Uncomment to see variable is parsed correctly
    #echo $MinerStats
    #echo "Hashrate: $HashRate"
    #echo "Worker: $Miner"
    #echo "Algo: $Algo"
    #echo "Uptime: $UpTime"

    # send metrics to InfluxDB
    # TODO: Don't forget to change InfluxDB host, user and password below
    curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' -u monero:some_password --data-binary "MinerMetrics,Miner=$Miner,Algo=$Algo UpTime=$UpTime,HashRate=$HashRate" &
done
wait
