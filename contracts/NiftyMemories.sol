// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SignableERC721.sol";

contract NiftyMemories{

     mapping(address => address) accounts;

    function createAccount() public returns (address account){
        require(accounts[msg.sender] == address(0), "Account exists");
        
        bytes memory bytecode = type(SignableERC721).creationCode;

        assembly {
            account := create2(0, add(bytecode, 32), mload(bytecode), 0)
        }

        accounts[msg.sender] = account;
    }

}