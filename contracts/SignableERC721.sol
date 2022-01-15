// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SignableERC721 is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint)  signRequestExpireDate;

    mapping(uint256 => EnumerableSet.AddressSet) tokenSignRequest;
    mapping(uint256 => EnumerableSet.AddressSet) tokenSignes;

    constructor() ERC721("Nifty Memories", "NFTM") {}

    function safeMint(address[] memory signees) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        signRequestExpireDate[tokenId] = block.timestamp + 7 days;

        for(uint i = 0; i < signees.length; i++){
             tokenSignRequest[tokenId].add(signees[i]);
        }
    }

    function signToken (uint256 tokenId) external{
        require(tokenSignRequest[tokenId].contains(msg.sender), "You can't sign this");
        require(block.timestamp < signRequestExpireDate[tokenId], "Sign request expired");

        tokenSignRequest[tokenId].remove(msg.sender); 
        tokenSignes[tokenId].add(msg.sender);
    }

    function getTokenSignees (uint256 tokenId) external view returns (address[] memory values){
        return tokenSignRequest[tokenId].values();
    }

    function getTokenSignRequests (uint256 tokenId) external view returns (address[] memory values){
        return tokenSignes[tokenId].values();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}