// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OutfitNFT.sol";

// import "@openzeppelin/contracts/introspection/IERC165.sol";
//import "./Royalty.sol";


//PR: contract FancyBee is ERC721, ERC2981ContractWideRoyalties {
contract FancyBee is ERC721 {


    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address internal fancyDAO;
    uint totalBeeSupply = 5;
    string originalURI;

    mapping (uint256=>address) outfitNFT; // maps beeIds to outfit contract
    mapping (uint256=>uint256) outfitTokenID; // maps beeIds to outfitIds

    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        _setBaseURI("ipfs://");
        // fancyDAO = DAOAddress;
        //PR: _setRoyalties(msg.sender, 1000); // Set caller (DAO?) as Receiver and Roaylty as 10%
    }

    // Modifier to check that the token is not <= 0.
    modifier TIDoutOfRange(uint256 _tokenID) {
        require (_tokenID>0, "TokenID out of range");
        _;
    }

    function mintToken(address owner, string memory metadataURI)
    public
    returns (uint256)
    {
        // require( balanceOf(msg.sender) == 0, "Sorry, only one bee per person." );
        require( totalSupply() < totalBeeSupply, "Sorry only 5 are available at this time. ");
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        originalURI = metadataURI;
        return id;
    }
    
    // When changing the metadata w/ Web3. Must be formatted like : bafy.../metadata.json
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external TIDoutOfRange(_tokenId) returns (string memory) {
        _setTokenURI(_tokenId, _tokenURI);
        return tokenURI(_tokenId);
    }

    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view TIDoutOfRange(_tokenId) returns (address receiver, uint256 amount){
    //     return (fancyDAO, _price/10);
    // }

    // Returns True if the token exists, else false.
    function tokenExists(uint256 _tokenId) external view returns (bool){
        return _exists(_tokenId);
    }

    // Called by the DAO to attach an outfit to a bee.
    function attachOutfit(uint256 _beeID, address _outfitContract, uint256 _outfitID) public {
        require(msg.sender == fancyDAO, "Not fancyDAO");
        require(OutfitNFT(_outfitContract).isOwnedBy(_beeID), "Bee is not owner"); //check the outfit is ours
        outfitNFT[_beeID] = _outfitContract;
        outfitTokenID[_beeID] = _outfitID;
    }
}