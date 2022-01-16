// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SignableERC721.sol";
//import "./SignPaymaster.sol";

contract NiftyMemories{

     mapping(address => address) public accounts;

    function createAccount() public returns (address account){
        require(accounts[msg.sender] == address(0), "Account exists");

        address polygonForwader = 0xF65De530849aC11d6931b07A52C17e054489920e;
        //accept everything paymaster
        address paymasterAddress = 0x5566b6DE069c8c60caD808E133f513AE9AD2Eb5a;

        // SignPaymaster accountPaymaster = new SignPaymaster();
        // accountPaymaster.whitelistTarget(account);
        // paymasterAddress = address(accountPaymaster);

        account = address(new SignableERC721(polygonForwader, paymasterAddress));


        accounts[msg.sender] = account;

        SignableERC721(account).transferOwnership(msg.sender);
    }

}