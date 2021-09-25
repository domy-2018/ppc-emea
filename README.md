# Plutus Pioneer Capstone Challenge - Simulate Wallet Quickstart

This repository describes a cardano-cli wrapper which creates any number of specified wallets and redistributes all the Ada within it equally.

When developers test their Dapps, quite often they will need a certain number of wallets to test.
After testing, the Ada amount within the wallets will be distributed in a fragmented fashion.
As in, some wallets will have a lot of Ada, and some wallets will be empty.

This utility will allow the developer to quickly redistribute all the Ada of all the test wallets equally,
so that all wallets will contain an equal amount of Ada.

## 
