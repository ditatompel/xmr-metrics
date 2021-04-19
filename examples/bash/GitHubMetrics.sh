#!/bin/bash
# GitHubMetrics.sh
#
# This script used to fetch monero-project/monero repository metrics from GitHub.

GitHubMetrics=$(curl -s https://api.github.com/repos/monero-project/monero -H 'Accept: application/vnd.github.v3+json')

LastUpdate=$(echo $GitHubMetrics | jq -r '.updated_at')
LastUpdate=$(date -u -d $LastUpdate +"%s")
RepoSize=$(echo $GitHubMetrics | jq -r '.size')
StarsCount=$(echo $GitHubMetrics | jq -r '.stargazers_count')
WatchersCount=$(echo $GitHubMetrics | jq -r '.watchers_count')
ForksCount=$(echo $GitHubMetrics | jq -r '.forks_count')
OpenIssuesCount=$(echo $GitHubMetrics | jq -r '.open_issues_count')
SubscribersCount=$(echo $GitHubMetrics | jq -r '.subscribers_count')

# Debug: Uncomment to see variable is parsed correctly
#echo "LastUpdate: $LastUpdate"
#echo "RepoSize: $RepoSize"
#echo "StarsCount: $StarsCount"
#echo "WatchersCount: $WatchersCount"
#echo "ForksCount: $ForksCount"
#echo "OpenIssuesCount: $OpenIssuesCount"
#echo "SubscribersCount: $SubscribersCount"

# send metrics to InfluxDB
# TODO: Don't forget to change InfluxDB host, user and password below
curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' --data-binary "GitHubInfo,Owner=monero-project,Repo=monero LastUpdate=$LastUpdate,RepoSize=$RepoSize,Stars=$StarsCount,Watchers=$WatchersCount,Forks=$ForksCount,OpenIssues=$OpenIssuesCount,Subscribers=$SubscribersCount" -u monero:some_password
