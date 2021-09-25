Note: Evidence for test cases below is documented in Word document


Test 1 - Test creating wallets by running the following command
==============================================================
./wallet-quickstart.sh -i 5

Check home directory to ensure that 5 wallets with addresses, verification keys, and signing keys have been created

Test 2 - Test that amounts are redistributed
============================================
With the wallets created in test 1, get some test ada from the faucet:
https://developers.cardano.org/docs/integrate-cardano/testnet-faucet

Run the following command to redistribute the Ada from the faucet:

./wallet-quickstart.sh -d ~/wallet_20210925215218

Note: replace wallet location with the actual locatino created in Test 1

Wait a few moments and run the following command to check that wallet amounts have indeed been redistributed

./wallet-quickstart.sh -q ~/wallet_20210925215218

Test 3 - Test that multiple UTXOs can be redistributed
======================================================
Send some Ada from one of the wallets to another, to create multiple UTXOs under one address

Run the command again to redistribute the Ada:

./wallet-quickstart.sh -d ~/wallet_20210925215218

Wait a few moments and run the following command to check that wallet amounts have been redistributed

./wallet-quickstart.sh -q ~/wallet_20210925215218


