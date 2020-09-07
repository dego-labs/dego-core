echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener


echo "" >  ./deployments/PlayerBook.full.sol
cat  ./scripts/head.sol >  ./deployments/PlayerBook.full.sol
$TF_CMD ./contracts/referral/PlayerBook.sol >>  ./deployments/PlayerBook.full.sol 


echo "" >  ./deployments/LPTestERC20.full.sol
cat  ./scripts/head.sol >  ./deployments/LPTestERC20.full.sol
$TF_CMD ./contracts/test/LPTestERC20.sol >>  ./deployments/LPTestERC20.full.sol 

echo "" >  ./deployments/TestMSG.full.sol
cat  ./scripts/head.sol >  ./deployments/TestMSG.full.sol
$TF_CMD ./contracts/test/TestMSG.sol >>  ./deployments/TestMSG.full.sol 


echo "" >  ./deployments/TestArray.full.sol
cat  ./scripts/head.sol >  ./deployments/TestArray.full.sol
$TF_CMD ./contracts/test/TestArray.sol >>  ./deployments/TestArray.full.sol 

echo "deploy end....."