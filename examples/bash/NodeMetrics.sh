#!/bin/bash
# NodeMetrics.sh
#
# This script used to fetch monerod node information (get_info) method via its
# JSON PRC and store it to InfluxDB.

# This example fetch public node info using restriced-rpc.
# If you run local node and want to  monitor it, you can run this script from
# your local Monero node machine. Change HTTP JSON RPC URL and port below.
# Default is http://127.0.0.1:18081/json_rpc
NodeInfo=$(curl -s http://node1.xmrindo.my.id:18089/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' -H 'Content-Type: application/json')

IsBusy=$(echo $NodeInfo | jq -r '.result.busy_syncing')
Credits=$(echo $NodeInfo | jq -r '.result.credits')
Difficulty=$(echo $NodeInfo | jq -r '.result.difficulty')
DBSize=$(echo $NodeInfo | jq -r '.result.database_size')
FreeSpace=$(echo $NodeInfo | jq -r '.result.free_space')
BlockHeight=$(echo $NodeInfo | jq -r '.result.height')
TXCount=$(echo $NodeInfo | jq -r '.result.tx_count')
TXPoolSize=$(echo $NodeInfo | jq -r '.result.tx_pool_size')
IncomingConnectionCount=$(echo $NodeInfo | jq -r '.result.incoming_connections_count')
OutgoingConnectionCount=$(echo $NodeInfo | jq -r '.result.outgoing_connections_count')
RPCConnectionCount=$(echo $NodeInfo | jq -r '.result.rpc_connections_count')
StartTime=$(echo $NodeInfo | jq -r '.result.start_time')
Synchronized=$(echo $NodeInfo | jq -r '.result.synchronized')
Status=$(echo $NodeInfo | jq -r '.result.status')
UpdateAvailable=$(echo $NodeInfo | jq -r '.result.update_available')
GreyPeerSize=$(echo $NodeInfo | jq -r '.result.grey_peerlist_size')
WhitePeerSize=$(echo $NodeInfo | jq -r '.result.white_peerlist_size')

# Debug: Uncomment to see variable is parsed correctly
#echo "IsBusy $IsBusy"
#echo "Credits $Credits"
#echo "Difficulty $Difficulty"
#echo "DBSize $DBSize"
#echo "FreeSpace $FreeSpace"
#echo "BlockHeight $BlockHeight"
#echo "TXCount $TXCount"
#echo "TXPoolSize $TXPoolSize"
#echo "IncomingConnectionCount $IncomingConnectionCount"
#echo "OutgoingConnectionCount $OutgoingConnectionCount"
#echo "RPCConnectionCount $RPCConnectionCount"
#echo "StartTime $StartTime"
#echo "Synchronized $Synchronized"
#echo "Status $Status"
#echo "UpdateAvailable $UpdateAvailable"
#echo "GreyPeerSize $GreyPeerSize"
#echo "WhitePeerSize $WhitePeerSize"

# send metrics to InfluxDB
# TODO: Don't forget to change InfluxDB host, user and password below
curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' -u monero:some_password --data-binary "NodeInfo,Node=node1xmrindo Diff=$Difficulty,IsBusy=$IsBusy,Credits=$Credits,StartTime=$StartTime,Synchronized=$Synchronized,GreyPeerSize=$GreyPeerSize,WhitePeerSize=$WhitePeerSize,UpdateAvailable=$UpdateAvailable,DBSize=$DBSize,FreeSpace=$FreeSpace,BlockHeigh=$BlockHeight,TXCount=$TXCount,TXPoolSize=$TXPoolSize,InConnCount=$IncomingConnectionCount,OutConnCount=$OutgoingConnectionCount,RPCConnCount=$RPCConnectionCount"
