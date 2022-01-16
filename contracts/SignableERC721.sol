// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SignPaymaster.sol";

contract SignableERC721 is ERC721, ERC721Enumerable, Ownable, BaseRelayRecipient{
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint)  signRequestExpireDate;

    mapping(uint256 => EnumerableSet.AddressSet) tokenSignRequest;
    mapping(uint256 => EnumerableSet.AddressSet) tokenSignes;
    mapping(uint256 => string) uris;

    event RequestSign(uint tokenId, address[] addresses);
    event Signed(uint tokenId, address signerAddress);

    address public myPaymaster;

    constructor(address forwarder, address paymaster) ERC721("Nifty Memories", "NFTM") {
        _setTrustedForwarder(forwarder);
        myPaymaster = paymaster;
    }

    function safeMintPrivateSign(uint expireTime, string memory uri, address[] memory signees) public onlyOwner returns (uint tokenId){
         require(signees.length > 0, "Use public sign with zero time if you want no signees");

        tokenId = mintCommon(expireTime, uri);

        for(uint i = 0; i < signees.length; i++){
             tokenSignRequest[tokenId].add(signees[i]);
        }

        emit RequestSign(tokenId, signees);
    }

    function safeMintPublicSign(uint expireTime, string memory uri) public onlyOwner returns (uint tokenId){
        tokenId = mintCommon(expireTime, uri);
    }

    function mintCommon(uint expireTime, string memory uri) private returns (uint tokenId){
        tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
        uris[tokenId] = uri;
        
        if(expireTime != 0){
            signRequestExpireDate[tokenId] = block.timestamp + expireTime;
        }
    }

    function signToken(uint256 tokenId) external{
        bool isPublic = isTokenPubliclySigned(tokenId);
        require(tokenSignRequest[tokenId].contains(_msgSender()) || isPublic, "You can't sign this");
        require(isTokenSignActive(tokenId), "Sign request expired");

        if(!isPublic){
            tokenSignRequest[tokenId].remove(_msgSender()); 
        }

        tokenSignes[tokenId].add(_msgSender());
        emit Signed(tokenId, _msgSender());
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uris[tokenId];
    }

    function isTokenPubliclySigned(uint tokenId) public view returns (bool){
        require(_exists(tokenId), "No such token");
        return tokenSignRequest[tokenId].length() == 0;
    }

    function isTokenSignActive(uint tokenId) public view returns (bool){
        require(_exists(tokenId), "No such token");
        return signRequestExpireDate[tokenId] != 0 && block.timestamp < signRequestExpireDate[tokenId];
    }

    function getTokenSignees(uint256 tokenId) external view returns (address[] memory values){
        require(_exists(tokenId), "No such token");
        return tokenSignes[tokenId].values();
    }

    function getTokenSignRequests(uint256 tokenId) external view returns (address[] memory values){
        require(_exists(tokenId), "No such token");
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

    string public override versionRecipient = "2.2.0";

    function _msgSender() internal view override(Context, BaseRelayRecipient)
        returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(Context, BaseRelayRecipient)
        returns (bytes memory) {
        return BaseRelayRecipient._msgData();
    }
}
