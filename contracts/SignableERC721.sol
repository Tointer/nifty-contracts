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

    event RequestSign(uint tokenId, address[] addresses);
    event Signed(uint tokenId, address signerAddress);

    constructor() ERC721("Nifty Memories", "NFTM") {}

    function safeMintPrivateSign(uint expireTime, address[] memory signees) public onlyOwner returns (uint tokenId){
         require(signees.length > 0, "Use public sign with zero time if you want no signees");

        tokenId = mintCommon(expireTime);

        for(uint i = 0; i < signees.length; i++){
             tokenSignRequest[tokenId].add(signees[i]);
        }

        emit RequestSign(tokenId, signees);
    }

    function safeMintPublicSign(uint expireTime) public onlyOwner returns (uint tokenId){
        tokenId = mintCommon(expireTime);
    }

    function mintCommon(uint expireTime) private returns (uint tokenId){
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        
        if(expireTime != 0){
            signRequestExpireDate[tokenId] = block.timestamp + expireTime;
        }
    }

    function signToken(uint256 tokenId) external{
        bool isPublic = isTokenPubliclySigned(tokenId);
        require(tokenSignRequest[tokenId].contains(msg.sender) || isPublic, "You can't sign this");
        require(isTokenSignActive(tokenId), "Sign request expired");

        if(!isPublic){
            tokenSignRequest[tokenId].remove(msg.sender); 
        }

        tokenSignes[tokenId].add(msg.sender);
        emit Signed(tokenId, msg.sender);
    }

    function isTokenPubliclySigned(uint tokenId) public view returns (bool){
        return tokenSignRequest[tokenId].length() == 0;
    }

    function isTokenSignActive(uint tokenId) public view returns (bool){
        return signRequestExpireDate[tokenId] != 0 && block.timestamp < signRequestExpireDate[tokenId];
    }

    function getTokenSignees (uint256 tokenId) external view returns (address[] memory values){
        return tokenSignes[tokenId].values();
    }

    function getTokenSignRequests (uint256 tokenId) external view returns (address[] memory values){
        return tokenSignRequest[tokenId].values();
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