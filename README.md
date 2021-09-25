# Plutus Pioneer Capstone - Wallet Quickstart

This repository describes a cardano-cli wrapper which creates any number of specified wallets and redistributes all the Ada within it equally.

When developers test their Dapps, quite often they will need a certain number of wallets to test.
After testing, the Ada amount within the wallets will be distributed in a fragmented fashion.
Some wallets will have a lot of Ada, and some wallets will be empty.

This utility will allow the developer to quickly "defragment" all the Ada in all the test wallets,
so that all wallets will contain an equal amount of Ada.

## Parameters and Function description

The script accepts the following parameters:

 - -i \<number of wallets> -o \<folder location\>
 - -d \<folder location of wallets\>
 - -q \<folder location of wallets\>

-i for input   
-o for output   
The init option takes a number to create the number of wallets in the specified output folder location

-d for defrag  
The defrag option given a folder location of wallets will then redistribute all the Ada of the wallets within it

-q for query  
The query option given a folder location of wallets, will output a report of all the UTXOs in the wallets

## Assumptions made

Please ensure the following: 
 - cardano-node running and connected to mainnet  
 - cardano-cli is on your PATH
 - CARDANO_NODE_SOCKET_PATH variable is exported as a global variable

Wallet address files end with ".addr"  
Wallet verification key files are generated with ".vkey"  
Wallet signing key files end with ".skey"  

## Example

wallet-quickstart.sh -i 5 -o ~/wallets

This will create 5 wallets in the location ~/wallets with their corresponding public and signing key, and their addresses.

wallet-quickstart.sh -d ~/wallets

This will redistribute all the Ada of all the wallets within the ~/wallets directory

wallet-quickstart.sh -q ~/wallets

This will query all the utxos of wallet addresses in the ~/wallets directory


## Testing

 - Test creation of wallets
 - Test multiple utxo 
 - Test simple case of one utxo
 - Test no utxo in wallet address at all

## Improvements

Currently script does not redistribute custom tokens or Ada sitting on a utxo that has tokens on it

