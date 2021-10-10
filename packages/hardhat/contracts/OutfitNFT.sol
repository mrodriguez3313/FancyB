// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";
// import "./FancyBee.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract OutfitNFT is ERC721 {    

    address internal fancyDAO;

    using Counters for Counters.Counter;
   
    Counters.Counter private _tokenIdCounter;
    
    mapping (uint256=>address) outfitOwnerBee; // maps outfitTokenID to the Bee contract that owns it. (User does not own outfits.)
    mapping (uint256=>uint256) beeTokenID; // 

    constructor(address DAOAddress) ERC721("FancyOutfit", "FBOF") {
        _setBaseURI("ipfs://");
        fancyDAO = DAOAddress;
    }

    //TODO - register for ERC-1820
    //TODO Should split it 50:50 with th creator. Register Outfit with as royalty receiver and split.
    // function royaltyInfo(uint256 _tokenId, uint256 _price) external view returns (address receiver, uint256 amount){
    //     require (_tokenId>0, "TokenID out of range");
    //     return (fancyDAO, _price/10); //TODO need to forward price/5 to the creator.
    // }

    //==================================
    // SPECIAL FUNCIONALITY
    //
    
    // Returns True if the token exists, else false.
    function _outfitExists(uint256 _tokenId) public view returns (bool){
        return _exists(_tokenId);
    }
    
    function isOwnedBy(uint256 _beeID) public view returns (bool){
        return(beeTokenID[_beeID] != 0);
    }

    // Called by the DAO to ask outfit to attach to a bee. Must be called _before_ calling the bee
    function attachToBee(uint256 _outfitID, address _beeContract, uint256  _beeID) public {
        FancyBeeInterface fancyBee = FancyBeeInterface(_beeContract);
        require(msg.sender == fancyDAO, "Not fancyDAO");
        require (!_outfitExists(_outfitID), "Invalid outfit"); //check outfit exists.
        require (!fancyBee._beeExists(_beeID), "Invalid bee"); //check the bee exists
        // require (outfitOwnerBee[_outfitID] == address(0) && beeTokenID[_outfitID] == 0, "Already taken"); //check the outfit it available
        // outfitOwnerBee[_outfitID] = _contract;
        // beeTokenID[_outfitID] = _beeID;
        //  TODO _setTokenOWner(_contract, _beeID); //only the bee can control now (need better system)
        
    }
}

interface FancyBeeInterface {
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external returns (string memory);
    function _beeExists(uint256 _tokenId) external view returns (bool);
}