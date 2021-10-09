//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//PR: import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
//PR: import "./Royalty.sol";

//PR: contract FancyBee is ERC721, ERC2981ContractWideRoyalties {
contract FancyBee is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint totalBeeSupply = 5;

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        _setBaseURI("ipfs://");
        //PR: _setRoyalties(msg.sender, 1000); // Set caller (DAO?) as Receiver and Roaylty as 10%
    }

    function mintToken(address owner, string memory metadataURI)
    public
    returns (uint256)
    {
        require( balanceOf(msg.sender) == 0, "Sorry, only one bee per person." );
        require( totalSupply() < totalBeeSupply, "Sorry only 5 are available at this time. ");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);

        return id;
    }
    
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external returns (string memory) {
        _setTokenURI(_tokenId, _tokenURI);
        return tokenURI(_tokenId);
    }
}
