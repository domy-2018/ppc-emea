#!/bin/bash


# NOTE: I originally wanted to write automated test cases, but ran out of time
# as it was more complicated that I envisioned. 
# So, I have resorted to writing manual test cases and documenting test evidence in a Word doc

# The following are the unit test cases



# Test 1 - Test that new wallets can be created in a default folder location

echo "Test 1 - Test that new wallets can be created"
echo "Running ./wallet-quickstart.sh -i 5"
init_wallets=$(./wallet-quickstart.sh -i 5)

numwallets=$(echo $init_wallets | awk '{ print $2 }')
location=$(echo $init_wallets | awk ' print $6 }')

echo "number of wallets created: $numwallets"
echo "location created: $location"

count_skeys=$(ls -1 $location/*skey | wc -l)

if [ $count_skeys -eq $numwallets ]; then

   echo "Passed.. the correct number of skeys created in $location"
fi




