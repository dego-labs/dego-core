/***
 *    ██████╗ ███████╗ ██████╗  ██████╗ 
 *    ██╔══██╗██╔════╝██╔════╝ ██╔═══██╗
 *    ██║  ██║█████╗  ██║  ███╗██║   ██║
 *    ██║  ██║██╔══╝  ██║   ██║██║   ██║
 *    ██████╔╝███████╗╚██████╔╝╚██████╔╝
 *    ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ 
 *    
 * https://dego.finance
                                  
* MIT License
* ===========
*
* Copyright (c) 2020 dego
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/
// File: contracts/test/TestArray.sol

pragma solidity^0.5.5;

contract Test {
    
    struct structUser {
        uint value;
        uint index;
        bool exists;
    }

    mapping(address => structUser) public arrayStructs;
    
    address[] public addressIndexes;

    uint public totalValue = 0;
    
    function addAddress(uint _val) public returns (bool){
        // if user exists, add _val
        if (arrayStructs[msg.sender].exists ) {
            arrayStructs[msg.sender].value += _val;
        }
        else {
            // else its new user
            addressIndexes.push(msg.sender);
            arrayStructs[msg.sender].value = _val;
            arrayStructs[msg.sender].index = addressIndexes.length-1;
            arrayStructs[msg.sender].exists = true;
        }
        return true;
    }
    
    function deleteAddress() public returns (bool) {
        // if address exists
        if (arrayStructs[msg.sender].exists) {
            structUser memory deletedUser = arrayStructs[msg.sender];
            // if index is not the last entry
            if (deletedUser.index != addressIndexes.length-1) {
                // delete addressIndexes[deletedUser.index];
                // last strucUser
                address lastAddress = addressIndexes[addressIndexes.length-1];
                addressIndexes[deletedUser.index] = lastAddress;
                arrayStructs[lastAddress].index = deletedUser.index; 
            }
            delete arrayStructs[msg.sender];
            addressIndexes.length--;
            return true;
        }
    }
    
    function getAddresses() public view returns (address[] memory){
        return addressIndexes;    
    }
    
    function getTotalValue() public  returns (uint) {
        uint arrayLength = addressIndexes.length;
        uint total = 0;
        for (uint i=0; i<arrayLength; i++) {
            total += arrayStructs[addressIndexes[i]].value;
        }

        totalValue = total;
        return total;
    }
    
    function getTotalUsers() public view returns (uint) {
        return addressIndexes.length;
    }
}
