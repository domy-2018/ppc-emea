#!/bin/bash

usage() {
    echo "Usage: $0 [options]" 
    echo
    echo "-i <number of wallets>         This specifies how many wallets to create"
    echo "-o <output folder location>    This specifies the output location for created wallets"
    echo "-d <wallet folder location>    This specifies the folder location of all the wallets to defragment"
    echo "                               Defaults to ~/wallet_YYYYMMDDHHMMSS"
    echo "-q <wallet folder location>    Query all the utxos in the wallets in the folder location"
    exit 0
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
# loop and create the number of wallets required specified
if [ $INIT -ne 0 ]; then

    mkdir -p $OUTPUT

    for ((i = 1; i <= $INIT; i++));
    do
        echo $i
        cardano-cli address key-gen --verification-key-file $OUTPUT/wallet_$i.vkey --signing-key-file $OUTPUT/wallet_$i.skey
        cardano-cli address build --payment-verification-key-file $OUTPUT/wallet_$i.vkey --out-file $OUTPUT/wallet_$i.addr $TESTNET
    done
fi

# Algorithm to redistribute all the Ada
# -------------------------------------
# - Query all the utxos for all the wallets in the wallet folder specified
# - Loop through each utxo and build the tx-in, tx-out, the signing-key-file
#   At the same time, keep a count of all the adas in the UTXOs, and how many UTXOs
# - Build a raw transaction
# - From the raw transaction, calculate the fees required
# - Calculate the amount of lovelace to redistribute to all the wallets
# - Any leftovers from the calculations are added to the fees
# - Sign the transaction with all the required signing key files 
# - Submit the transaction
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

    echo "Total number of wallets to redistribute     : $counter"
    echo "The total amount of Ada to redistribute     : $total_less_fees lovelace"
    echo "After redistribution, each wallet will have : $equal_amounts lovelace"
    echo "Total fees for this transaction             : $minfee lovelace"
    echo

    cardano-cli transaction build-raw $txin $txout --fee $minfee --out-file tx-defrag.draft  
    echo "Draft transaction file build: tx-defrag.draft"

    cardano-cli transaction sign --tx-body-file tx-defrag.draft $txsign $TESTNET --out-file tx-defrag.signed
    echo "Transaction has been signed : tx-defrag.signed"

    echo
    echo "Submitting transaction: ..."
    echo 
    cardano-cli transaction submit --tx-file tx-defrag.signed $TESTNET

fi

# query all the UTXOs given a folder
# Loop through each wallet address file in the provided folder location
# print each UTXO
if [ $QUERY != "none" ]; then

    wallets=$(ls $QUERY/*.addr)

    echo "Query folder location: $QUERY"
    echo

    for w in $wallets
    do
        w_query_utxo=$(cardano-cli query utxo --address $(cat $w) $TESTNET | grep "lovelace + TxOutDatumHashNone")

        echo $(basename $w)
        echo "$w_query_utxo" | while read -r line
        do
            echo "$line" | awk '{ print "  -- "$1"#"$2" - "$3" lovelace" }'
        done

    done

fi
