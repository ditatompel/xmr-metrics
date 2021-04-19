#!/bin/bash
# IndodaxExchange.sh
#
# This script used to fetch public market data from "Indodax" Exchange.
# Please see https://github.com/btcid/indodax-official-api-docs/blob/master/Public-RestAPI.md#summaries
# for more details.

CoinPrices=$(curl -s https://indodax.com/api/summaries -H 'Content-Type: application/json')

XmrHigh=$(echo $CoinPrices | jq -r '.tickers.xmr_idr.high')
XmrLow=$(echo $CoinPrices | jq -r '.tickers.xmr_idr.low')
XmrVol=$(echo $CoinPrices | jq -r '.tickers.xmr_idr.vol_xmr')
XmrVolIdr=$(echo $CoinPrices | jq -r '.tickers.xmr_idr.vol_idr')
XmrLast=$(echo $CoinPrices | jq -r '.tickers.xmr_idr.last')
Xmr24h=$(echo $CoinPrices | jq -r '.prices_24h.xmridr')
Xmr7d=$(echo $CoinPrices | jq -r '.prices_7d.xmridr')

# Debug: Uncomment to see variable is parsed correctly
#echo "XMR High: $XmrHigh"
#echo "XMR Low: $XmrLow"
#echo "XMR Vol: $XmrVol"
#echo "XMR VolIdr: $XmrVolIdr"
#echo "XMR Last: $XmrLast"
#echo "XMR 24h: $Xmr24h"
#echo "XMR 7d: $Xmr7d"

# send metrics to InfluxDB
# TODO: Don't forget to change InfluxDB host, user and password below
curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' --data-binary "CoinInfo,Coin=XMR,Exchange=Indodax Last=$XmrLast,High=$XmrHigh,Low=$XmrLow,Vol=$XmrVol,VolCurrency=$XmrVolIdr,24h=$Xmr24h,7d=$Xmr7d" -u monero:some_password &


# You can add other currency if you want to.
# For example BTC.
#BtcHigh=$(echo $CoinPrices | jq -r '.tickers.btc_idr.high')
#BtcLow=$(echo $CoinPrices | jq -r '.tickers.btc_idr.low')
#BtcVol=$(echo $CoinPrices | jq -r '.tickers.btc_idr.vol_btc')
#BtcVolIdr=$(echo $CoinPrices | jq -r '.tickers.btc_idr.vol_idr')
#BtcLast=$(echo $CoinPrices | jq -r '.tickers.btc_idr.last')
#Btc24h=$(echo $CoinPrices | jq -r '.prices_24h.btcidr')
#Btc7d=$(echo $CoinPrices | jq -r '.prices_7d.btcidr')

#echo "BTC High: $BtcHigh"
#echo "BTC Low: $BtcLow"
#echo "BTC Vol: $BtcVol"
#echo "BTC VolIdr: $BtcVolIdr"
#echo "BTC Last: $BtcLast"
#echo "BTC 24h: $Btc24h"
#echo "BTC 7d: $Btc7d"

#curl -i -XPOST 'http://92.168.1.248:8086/write?db=MoneroMetrics' --data-binary "CoinInfo,Coin=BTC,Exchange=Indodax Last=$BtcLast,High=$BtcHigh,Low=$BtcLow,Vol=$BtcVol,VolCurrency=$BtcVolIdr,24h=$Btc24h,7d=$Btc7d" -u monero:some_password &

# or ETH
#EthHigh=$(echo $CoinPrices | jq -r '.tickers.eth_idr.high')
#EthLow=$(echo $CoinPrices | jq -r '.tickers.eth_idr.low')
#EthVol=$(echo $CoinPrices | jq -r '.tickers.eth_idr.vol_eth')
#EthVolIdr=$(echo $CoinPrices | jq -r '.tickers.eth_idr.vol_idr')
#EthLast=$(echo $CoinPrices | jq -r '.tickers.eth_idr.last')
#Eth24h=$(echo $CoinPrices | jq -r '.prices_24h.ethidr')
#Eth7d=$(echo $CoinPrices | jq -r '.prices_7d.ethidr')

#echo "ETH High: $EthHigh"
#echo "ETH Low: $EthLow"
#echo "ETH Vol: $EthVol"
#echo "ETH VolIdr: $EthVolIdr"
#echo "ETH Last: $EthLast"
#echo "ETH 24h: $Eth24h"
#echo "ETH 7d: $Eth7d"

#curl -i -XPOST 'http://92.168.1.248:8086/write?db=MoneroMetrics' --data-binary "CoinInfo,Coin=ETH,Exchange=Indodax Last=$EthLast,High=$EthHigh,Low=$EthLow,Vol=$EthVol,VolCurrency=$EthVolIdr,24h=$Eth24h,7d=$Eth7d" -u monero:some_password &

wait
