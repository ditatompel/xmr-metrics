#!/bin/bash
# PoolMetrics.sh
#
# This script used to fetch pool information via its API and store it to
# InfluxDB. Currently, only mining pool who use jtgrassie and snipa22 backend is
# supported.
# Feel free to edit this script and add your favorite mining pool backend. =)


# Because bash does not support multidimensional arrays, let's separate each
# pool params with "|" sign and split them into array latter.
#
# Params:
# PoolHosts=(
#     "[POOL_NAME]|[API_URL]||[POOL_BACKEND_AUTHOR]|[XMR_WALLET_ADDRESS]"
#     "[POOL_NAME2]|[API_URL2]||[POOL_BACKEND_AUTHOR2]|[XMR_WALLET_ADDRESS2]"
#     // etc
# )
#
# POOL_NAME           : Name of the pool you want to display on Grafana
# API_URL             : Starting point API URL of the pool
# POOL_BACKEND_AUTHOR : Author name of mining pool software used by the pool.
#                       Either 'jtgrassie' or 'snipa22'.
#                       it's quite easy to find pool backend and usually each
#                       frontend design quite similar.
#                       For example: monerop.com, xmrvsbeast.com using jtgrassie
#                       and moneroocean.stream, moneromine.co using snipa22.
# XMR_WALLET_ADDRESS  : Your XMR address
# Eg:
PoolHosts=(
    "xmrvsbeast|https://xmrvsbeast.com|jtgrassie|888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H"
    "xmrindo|https://xmrindo.my.id/stats|schernykh|WALLET_ADDRESS_IS_NOT_REQUIRED_FOR_P2POOL"
    "xmrfast|https://xmrfast.com/api|snipa22|888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H"
    "moneroocean|https://api.moneroocean.stream|snipa22|888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H"
)

for host in "${PoolHosts[@]}"
do
    # Split PoolHosts param into array with "|" sign.
    IFS='|' read -ra POOLPARAMS <<< "$host"

    # condition when pool is use https://github.com/jtgrassie/monero-pool
    if [[ ${POOLPARAMS[2]} == 'jtgrassie' ]]
    then
        # Curl cookie param "wa" is used for jtgrassie/monero-pool
        PoolInfo=$(curl --cookie "wa=${POOLPARAMS[3]}" -s ${POOLPARAMS[1]}/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        PoolHR=$(echo $PoolInfo | jq -r '.pool_hashrate')
        RoundHashes=$(echo $PoolInfo | jq -r '.round_hashes')
        LastBlockFound=$(echo $PoolInfo | jq -r '.last_block_found')
        PoolBlockFound=$(echo $PoolInfo | jq -r '.pool_blocks_found')
        ConnectedMiners=$(echo $PoolInfo | jq -r '.connected_miners')
        NetworkDiff=$(echo $PoolInfo | jq -r '.network_difficulty')
        NetworkHeight=$(echo $PoolInfo | jq -r '.network_height')
        MinerHashrate=$(echo $PoolInfo | jq -r '.miner_hashrate')
        MinerBalance=$(echo $PoolInfo | jq -r '.miner_balance')

        # For now, lest skip information about Network Hashrates, Pool Fee,
        # and Minimum pool payout because not all mining pool backend provide
        # these informations
        #NetworkHR=$(echo $PoolInfo | jq -r '.network_hashrate')
        #PayMin=$(echo $PoolInfo | jq -r '.payment_threshold')
        #PoolFee=$(echo $PoolInfo | jq -r '.pool_fee')
    elif [[ ${POOLPARAMS[2]} == 'schernykh' ]]
    then
        # condition when pool is use https://github.com/SChernykh/p2pool
        PoolInfo=$(curl -s ${POOLPARAMS[1]}/pool/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        # Get information about network difficulty and network height based
        # from pool API.
        NetworkInfo=$(curl -s ${POOLPARAMS[1]}/network/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        # Since P2Pool v1.2, Users can pass --stratum-api to command line to
        # enable statistics from StratumServer status command in JSON format.
        StratumInfo=$(curl -s ${POOLPARAMS[1]}/local/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        PoolHR=$(echo $PoolInfo | jq -r '.pool_statistics.hashRate')
        LastBlockFound=$(echo $PoolInfo | jq -r '.pool_statistics.lastBlockFoundTime')
        PoolBlockFound=$(echo $PoolInfo | jq -r '.pool_statistics.totalBlocksFound')
        ConnectedMiners=$(echo $PoolInfo | jq -r '.pool_statistics.miners')

        NetworkDiff=$(echo $NetworkInfo | jq -r '.difficulty')
        NetworkHeight=$(echo $NetworkInfo | jq -r '.height')

        MinerHashrate=$(echo $StratumInfo | jq -r '.hashrate_15m')
        # For now, lest skip information about Round Hashes and Miner Balance
        # because p2pool is not public pool.
        RoundHashes=0
        MinerBalance=0
    else
        # condition when pool is use https://github.com/Snipa22/nodejs-pool

        # Get information about pool hashrate, round hashes, etc
        PoolInfo=$(curl -s ${POOLPARAMS[1]}/pool/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        # Get information about network difficulty and network height based
        # from pool API.
        NetworkInfo=$(curl -s ${POOLPARAMS[1]}/network/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        # Get information about miner hashrate and balance.
        MinerInfo=$(curl -s ${POOLPARAMS[1]}/miner/${POOLPARAMS[3]}/stats -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache')

        PoolHR=$(echo $PoolInfo | jq -r '.pool_statistics.hashRate')
        RoundHashes=$(echo $PoolInfo | jq -r '.pool_statistics.roundHashes')
        LastBlockFound=$(echo $PoolInfo | jq -r '.pool_statistics.lastBlockFoundTime')
        PoolBlockFound=$(echo $PoolInfo | jq -r '.pool_statistics.totalBlocksFound')
        ConnectedMiners=$(echo $PoolInfo | jq -r '.pool_statistics.miners')
        NetworkDiff=$(echo $NetworkInfo | jq -r '.difficulty')
        NetworkHeight=$(echo $NetworkInfo | jq -r '.height')
        MinerHashrate=$(echo $MinerInfo | jq -r '.hash')
        MinerBalance=$(echo $MinerInfo | jq -r '.amtDue')
        MinerBalance=$(echo "$MinerBalance/1000000000000" | bc -l | awk '{printf "%.8f", $0}')
    fi

    # Debug: Uncomment to see variable is parsed correctly
    #echo $PoolInfo
    #echo "POOL HR $PoolHR"
    #echo "Round HR $RoundHashes"
    #echo "Network Diff $NetworkDiff"
    #echo "Network height $NetworkHeight"
    #echo "Last Block Found $LastBlockFound"
    #echo "Pool Block Found $PoolBlockFound"
    #echo "Connected Miners $ConnectedMiners"
    #echo "Miner Hashrate $MinerHashrate"
    #echo "Miner Balance $MinerBalance"

    # send metrics to InfluxDB
    # TODO: Don't forget to change InfluxDB host, user and password below
    curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' -u monero:some_password --data-binary "PoolInfo,Node=${POOLPARAMS[0]} PoolHR=$PoolHR,RoundHR=$RoundHashes,NetDiff=$NetworkDiff,NetHeight=$NetworkHeight,LastBlock=$LastBlockFound,BlockFound=$PoolBlockFound,CountMiners=$ConnectedMiners,MyHashrate=$MinerHashrate,MyBalance=$MinerBalance"
done
