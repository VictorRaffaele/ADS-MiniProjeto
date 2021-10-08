#!/bin/bash

echo "amostra interface recebido pacote_rec enviado pacote_env tempo" > log_rede.txt
amostra=0

while [ TRUE ]
do

rec_local=`cat /proc/net/dev | grep "lo" | awk '{print $2}'`
rec_pack_lo=`cat /proc/net/dev | grep "lo" | awk '{print $3}'`

send_local=`cat /proc/net/dev | grep "lo" | awk '{print $10}'`
send_pack_lo=`cat /proc/net/dev | grep "lo" | awk '{print $11}'`

rec_ens33=`cat /proc/net/dev | grep "ens33" | awk '{print $2}'`
rec_pack_ens33=`cat /proc/net/dev | grep "ens33" | awk '{print $3}'`

send_ens33=`cat /proc/net/dev | grep "ens33" | awk '{print $10}'`
send_pack_ens33=`cat /proc/net/dev | grep "ens33" | awk '{print $11}'`

data=`date`

amostra=`expr $amostra + 1`

echo $amostra "      lo:      " $rec_local "  " $rec_pack_lo "      " $send_local " " $send_pack_lo "      " $data >> log_rede.txt
echo "        ens33:   " $rec_ens33 " " $rec_pack_ens33 "    " $send_ens33 "" $send_pack_ens33 >> log_rede.txt
sleep 15
done