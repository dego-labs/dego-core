pragma solidity ^0.5.0;


interface IPool {
    function totalPower( ) external view returns (uint256);
    function balanceOfPower( address player ) external view returns (uint256);
}
