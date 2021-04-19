#!/bin/bash
# RedditMetrics.sh
#
# This script used to fetch r/Monero subreddit metrics from Reddit.

RedditMetrics=$(curl -s -A "linux:ditatompel API for Reddit:v0.0.1 (by /u/ditatompel)" https://www.reddit.com/r/Monero/about.json)

ActiveUser=$(echo $RedditMetrics | jq -r '.data.active_user_count')
Subscriers=$(echo $RedditMetrics | jq -r '.data.subscribers')

# Debug: Uncomment to see variable is parsed correctly
#echo "ActiveUser: $ActiveUser"
#echo "Subscriers: $Subscriers"

# send metrics to InfluxDB
# TODO: Don't forget to change InfluxDB host, user and password below
curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' -u monero:some_password --data-binary "RedditInfo,Subreddit=Monero ActiveUser=$ActiveUser,Subscriers=$Subscriers"
