#!/bin/bash

usage() {
    echo "usage help" 
    exit 1
}

# default values
DATETIMESTAMP=$(date +%Y%m%d%H%M%S)
INIT=0
OUTPUT=~/wallet_${DATETIMESTAMP}
DEFRAG="none"
QUERY="none"
TESTNET="--testnet-magic 1097911063"
cardano-cli query protocol-parameters --testnet-magic 1097911063 --out-file "testnet-protocol-parameters.json"
PROTOCOL="testnet-protocol-parameters.json"


optstring="i:o:d:q:"

while getopts $optstring options; do

    case "${options}" in
        i)
            INIT=${OPTARG}
            ;;
        o)
            OUTPUT=${OPTARG}
            ;;
        d)
            DEFRAG=${OPTARG}
            ;;
        q)
            QUERY=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# creating and initializing wallets
# loop through and create the number of wallets required.
if [ $INIT -ne 0 ]; then

    mkdir -p $OUTPUT

    for ((i = 1; i <= $INIT; i++));
    do
        echo $i
        cardano-cli address key-gen --verification-key-file $OUTPUT/wallet_$i.vkey --signing-key-file $OUTPUT/wallet_$i.skey
        cardano-cli address build --payment-verification-key-file $OUTPUT/wallet_$i.vkey --out-file $OUTPUT/wallet_$i.addr $TESTNET
    done
fi


# strategy to redistribute ada
# Query all the UTXOs of all the wallet addresses.
# create a transaction with an input of all the UTXOs, and an output to all the wallet addresses in an equally distributed fashion
if [ $DEFRAG != "none" ]; then

    wallets=$(ls $DEFRAG/*.addr)
    counter=0
    txin=""
    txincount=0
    txout=""
    txsign=""
    txsigncount=0
    totalada=0

    for w in $wallets
    do
        w_query_utxo=$(cardano-cli query utxo --address $(cat $w) $TESTNET | grep "lovelace + TxOutDatumHashNone")

        if [ "$w_query_utxo" != "" ]; then
    
            txin_loop_count=0
            totalada_loop=0
            lines=$(echo "$w_query_utxo")
            while read -r line
            do
                w_utxo=$(echo "$line" | awk '{ print $1"#"$2 }')
                txin="$txin"" --tx-in $w_utxo"
                txin_loop_count=$(expr $txin_loop_count + 1)

                ada=$(echo "$line" | awk '{ print $3 }')
                totalada_loop=$(expr $totalada_loop + $ada)
            done <<< "$lines"

            txincount=$(expr $txincount + $txin_loop_count)
            totalada=$(expr $totalada + $totalada_loop) 

            wsign=$(echo $w | sed 's/^\(.*\)\.addr$/\1\.skey/')
            txsign="$txsign"" --signing-key-file $wsign"
            txsigncount=$(expr $txsigncount + 1)

        fi

        txout="$txout"" --tx-out $(cat $w)+0"
        counter=$(expr $counter + 1)

    done

    # build raw transaction
    cardano-cli transaction build-raw $txin $txout --fee 0 --out-file tx-defrag.draft

    # calculate fees
    minfee=$(cardano-cli transaction calculate-min-fee --tx-body-file tx-defrag.draft --tx-in-count $txincount --tx-out-count $counter --witness-count $txsigncount $TESTNET --protocol-params-file $PROTOCOL)
    minfee=$(echo "$minfee" | awk '{ print $1 }')

    total_less_fees=$(expr $totalada - $minfee)
    
    equal_amounts=$(expr $total_less_fees / $counter)
    leftover=$(expr $total_less_fees % $counter)
    minfee=$(expr $minfee + $leftover )

    txout=$(echo $txout | sed 's/+0/+'"$equal_amounts"'/g')

    cardano-cli transaction build-raw $txin $txout --fee $minfee --out-file tx-defrag.draft  

    cardano-cli transaction sign --tx-body-file tx-defrag.draft $txsign $TESTNET --out-file tx-defrag.signed

    cardano-cli transaction submit --tx-file tx-defrag.signed $TESTNET

    echo "totalada: "$totalada
    echo "total_less_fees: "$total_less_fees
    echo "fees: "$minfee
    echo "equal_amounts: "$equal_amounts
    echo "leftover: "$leftover
    echo $txin
    echo $txout
    echo $txsign
    echo $txincount
    echo $counter
    echo "totalada: "$totalada

fi

# query all the UTXOs given a folder
if [ $QUERY != "none" ]; then

    wallets=$(ls $QUERY/*.addr)

    for w in $wallets
    do
        w_query_utxo=$(cardano-cli query utxo --address $(cat $w) $TESTNET | grep "lovelace + TxOutDatumHashNone")
        echo "$w"
        echo "$w_query_utxo"

        echo "$w_query_utxo" | while read -r line
        do
            w_utxo=$(echo "$line" | awk '{ print $1"#"$2 }')
        done


    done

fi
