#!/bin/bash

echo "amostra RX TX recebido enviado tempo" > log_rede.txt
amostra=0

while [ TRUE ]
do

rx=`/sbin/ifconfig "ens33" | grep "RX" | grep "bytes" | awk '{print $5}'`

tx=`/sbin/ifconfig "ens33" | grep "TX" | grep "bytes" | awk '{print $5}'`

recebido=`ifstat | awk '{print $0}'`

enviado=`ifstat | awk '{print $1}'`

data=`date`

amostra=`expr $amostra + 1`

echo $amostra $rx $tx $recebido $enviado $data >> log_rede.txt

done