pragma solidity ^0.5.0;


interface IAuctionReward {
    function endCheck( ) external returns (bool);
    function startCheck( )  external returns (bool);

}
