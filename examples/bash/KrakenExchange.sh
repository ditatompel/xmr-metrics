#!/bin/bash
# KrakenExchange.sh
#
# This script used to fetch Monero public market data from "Kraken" Exchange.
# Please see https://www.kraken.com/features/api for more information.

CoinPrices=$(curl -s https://api.kraken.com/0/public/Ticker?pair=XXMRZUSD -H 'Content-Type: application/json')

XmrHigh=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.h[0]')   # h[0]: today, h[1]: 24h
XmrLow=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.l[0]')    # l[0]: today, l[1]: 24h
XmrVol=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.v[0]')    # v[0]: today, v[1]: 24h
XmrVolUsd=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.p[0]') # p[0]: today, p[1]: 24h
XmrVolUsd=$(echo "$XmrVol*$XmrVolUsd" | bc -l | awk '{printf "%.2f", $0}')
XmrLast=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.c[0]')
Xmr24h=$(echo $CoinPrices | jq -r '.result.XXMRZUSD.p[1]')

# Debug: Uncomment to see variable is parsed correctly
#echo $CoinPrices
#echo "XMR High: $XmrHigh"
#echo "XMR Low: $XmrLow"
#echo "XMR Vol: $XmrVol"
#echo "XMR VolCurrency: $XmrVolUsd"
#echo "XMR Last: $XmrLast"
#echo "XMR 24h: $Xmr24h"

# send metrics to InfluxDB
# TODO: Don't forget to change InfluxDB host, user and password below
curl -i -XPOST 'http://192.168.1.248:8086/write?db=MoneroMetrics' --data-binary "CoinInfo,Coin=XMR,Exchange=Kraken Last=$XmrLast,VolCurrency=$XmrVolUsd,Vol=$XmrVol,High=$XmrHigh,Low=$XmrLow,24h=$Xmr24h" -u monero:some_password
