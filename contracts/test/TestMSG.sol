pragma solidity ^0.5.0;


import "../library/Governance.sol";

contract TestMsg is Governance {


    uint256 public _count = 0;

    function setCount( uint256 count )  public  onlyGovernance{
        _count = count;
    }

}