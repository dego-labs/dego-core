pragma solidity ^0.5.0;


interface IPowerStrategy {
    function lpIn(address sender, uint256 amount) external;
    function lpOut(address sender, uint256 amount) external;
    
    function getPower(address sender) view  external returns (uint256);
}
