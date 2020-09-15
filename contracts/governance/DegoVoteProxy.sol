

pragma solidity ^0.5.16;

import "../interface/IPool.sol";
import "../library/Governance.sol";

contract DegoVoterProxy is Governance {
    
    IPool public _pool = IPool(0x6666666666666666666666666666666666666666);
    
    function decimals() external pure returns (uint8) {
        return uint8(18);
    }
    
    function name() external pure returns (string memory) {
        return "dego.voteproxy";
    }
    
    function symbol() external pure returns (string memory) {
        return "DEGOVOTE";
    }
    
    function totalSupply() external view returns (uint) {
        return _pool.totalSupply();
    }
    
    function balanceOf(address voter) external view returns (uint) {
        uint votes = _pool.balanceOf(voter);
        return votes;
    }

    function setPool(address pool)  public  onlyGovernance{
        _pool = IPool(pool);
    }

    
    constructor() public {}
}