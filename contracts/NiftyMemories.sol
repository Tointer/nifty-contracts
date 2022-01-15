// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SignableERC721.sol";

contract NiftyMemories{

     mapping(address => address) public accounts;

    function createAccount() public returns (address account){
        require(accounts[msg.sender] == address(0), "Account exists");

        account = address(new SignableERC721());

        accounts[msg.sender] = account;

        SignableERC721(account).transferOwnership(msg.sender);
    }

}