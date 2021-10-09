// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./FancyBee.sol";


contract OutfitNFT is ERC721, FancyBee {    

    
    // address internal fancyDAO = msg.sender;
  
    using Counters for Counters.Counter;
 
    Counters.Counter private _tokenIdCounter;
    
    mapping (uint256=>address) beeNFT;
    mapping (uint256=>uint256) beeTokenID;

    constructor() ERC721("FancyOutfit", "FBOF") {}

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
        return(beeTokenID[_beeID] !=0);
    }

    // Called by the DAO to ask outfit to attach to a bee. Must be called _before_ calling the bee
    function attachToBee(uint256 _outfitID, address _contract, uint256  _beeID) public {
        require(msg.sender == fancyDAO, "Not fancyDAO");
        require (!_outfitExists(_outfitID), "Invalid outfit"); //check outfit exists.
        require (!_beeExists(_beeID), "Invalid bee"); //check the bee exists
        require (beeNFT[_outfitID] == address(0) || beeTokenID[_outfitID] == 0, "Already taken"); //check the outfit it available
        beeNFT[_outfitID] = _contract;
        beeTokenID[_outfitID] = _beeID;
        //  TODO _setTokenOWner(_contract, _beeID); //only the bee can control now (need better system)
        
    }
}