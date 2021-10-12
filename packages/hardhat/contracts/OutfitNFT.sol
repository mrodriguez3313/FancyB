// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract OutfitNFT is ERC721 {    

    address internal fancyDAO;

    using Counters for Counters.Counter;
   
    Counters.Counter private _outfitIdCounter;
    string originalOutfitURI;
    
    mapping (uint256 => string) SecretURIs;
    
    mapping (uint256=>address) outfitOwnerBee; // maps outfitTokenID to the BeeContract. (User does not own outfits.)
    mapping (uint256=>uint256) beeTokenID; // Maps outfitIds to BeeIds. 


    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        _setBaseURI("ipfs://");
        // fancyDAO = DAOAddress;
    }

    //TODO - register for ERC-1820
    //TODO Should split it 50:50 with th creator. Register Outfit with as royalty receiver and split.
    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 amount){
    //     require (_tokenId>0, "TokenID out of range");
    //     return (fancyDAO, _price/10); //TODO need to forward price/5 to the creator.
    // }
    
    function mintToken(address owner, string memory metadataURI)
    public
    returns (uint256)
    {
        require( balanceOf(msg.sender) == 0, "Sorry, only one bee per person." );
        _outfitIdCounter.increment();

        uint256 id = _outfitIdCounter.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        originalOutfitURI = metadataURI;
        return id;
    }
    
    //==================================
    // SPECIAL FUNCIONALITY
    //
    
    // Returns True if the token exists, else false.
    function tokenExists(uint256 _tokenId) public view returns (bool){
        return _exists(_tokenId);
    }
    
    function isOwnedBy(uint256 _beeID) public view returns (bool){
        return(beeTokenID[_beeID] != 0);
    }

    // Given an outfitId, return the the one with the bee attached.
    function getTokenURI(uint _outfitId) public view returns (string memory) {
        return "bafyreie2wx4due37g4bwv6askqtdntuhiim7elpcmagc7tjghjh5z5vpdm/metadata.json";
    }

    function setSecretTokenURI(string memory _secretURI, uint256 _oufitId) public {
        SecretURIs[_oufitId] = _secretURI;
    }

    // Called by the DAO to ask outfit to attach to a bee. Must be called _before_ calling the bee
    function attachToBee(uint256 _outfitID, address _beeContract, uint256  _beeID) public {
        // FancyBeeInterface fancyBee = FancyBeeInterface(_beeContract);
        require(msg.sender == fancyDAO, "Not fancyDAO");
        require (!tokenExists(_outfitID), "Invalid outfit"); //check outfit exists.
        require (outfitOwnerBee[_outfitID] != address(0), "Already taken"); //check the outfit is available, if the location is empty (0's), its available.
        outfitOwnerBee[_outfitID] = _beeContract;
        beeTokenID[_outfitID] = _beeID;
        // _setTokenOWner(_contract, _beeID); //Will be done by the DAO.
    }

    // function _transfer(address _from, address _to, uint _tokenId) internal override {
    //     require(outfitOwnerBee[_tokenId] == address(0),  "Transfer not allowed.");
    //     super._transfer(_from, _to, _tokenID);
    // }
}