echo "" >  ./deployments/UniswapV2ERC20Full.sol
cat  ./scripts/head.sol >  ./deployments/UniswapV2ERC20Full.sol
truffle-flattener ./contracts/UniswapV2ERC20.sol > ./contracts/UniswapV2ERC20Full.sol
#truffle-flattener ./contracts_uniswap/UniswapV2Factory.sol > ./deployments/UniswapV2FactoryFull.sol
#truffle-flattener ./contracts_uniswap/UniswapV2Pair.sol > ./deployments/UniswapV2PairFull.sol

truffle-flattener ./contracts_reward/BalancerRewards.sol > ./deployments/BalancerRewardsFull.sol
truffle-flattener ./contracts_reward/UniswapRewards.sol > ./deployments/UniswapRewardsFull.sol


truffle-flattener ./contracts_token/AirToken.sol > ./deployments/AirTokenFull.sol