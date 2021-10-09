// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// -------------
// FANCY BEE DAO
//
// This DAO esponsible for managing the treasury and all other contracts including:
//  - BeeNFTs, 
//  - HiveNFTs, 
//  - OutfitNFTs 
//
// All operations that involve a royalty to the DAO must be mediated
// thought this contract.
//
// The DAO is goverened though voting, where:
// - each bee has a vote
// - each Hive has a weighted vote.
// -------------

// TODO delete these until compile fails :)
// TODO may need to add interfaces for dependancies in different files.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./Royalty.sol";
//import "./BeeNFT.sol";
//import "./OutfitNFT.sol";
    
contract FancyBsDAO is Ownable {
    
        
    mapping (uint16=> uint256) public hiveBalance;
    mapping (uint16=> uint16) public hivePercent;
    mapping (uint16=> address) public reverseHiveMap;
    
    uint16 hiveCount = 0;

    uint256 public treasury; //Amount to be distributed
    uint256 public retained; //Amount held for DAO
    uint256 public daoPercent;// % to be retained by DAO
    uint256 public nextDistribution; // Timer to prevent high gas fees
    
    BeeNFT public beeNFT;
    HiveNFT public hiveNFT;// Charity = Hive
    OutfitNFT public outfitNFT; 
//  TODO: define governance by bees not ERC20
//  FancyBsGov public votingToken;
//  FancyBsGovenor public governor; 
    
    constructor(){
        //Create NFTs owned by the DAO
        beeNFT = new BeeNFT();
        hiveNFT = new HiveNFT();
        outfitNFT = new OutfitNFT();
        
        nextDistribution = block.timestamp + 604800;  // only allow distribution weekly

//        votingToken = new FancyBsGov();
//        governor = new FancyBsGovenor(votingToken);

    }
    
    // Allows the DAO to take ownership of the whole ecosystem.
    function setOwnership(address _addr) public onlyOwner {
        beeNFT.transferOwnership(_addr);
        hiveNFT.transferOwnership(_addr);
        outfitNFT.transferOwnership(_addr);
//      votingToken.transferOwnership(_addr);
    }
    
    //Recieve all ETH there.  (TODO: ERC20s are permissioned and accumulated in the ERC20 contract)
    receive() external payable {
        treasury += msg.value;
    }
    
    //
    // Interface to Beekeeper
    //
    function dressMe(uint256 _beeID, uint256 _outfitID) public payable {
        require ( msg.value != 10^16, "Please send exactly x 0.01 ETH.");
        outfitNFT.attachToBee(_outfitID, address(beeNFT), _beeID);
        beeNFT.attachOutfit(_beeID, address(outfitNFT), _outfitID);
        treasury += msg.value;
    } 
    
    //
    // voting
    //

    uint256 proposalTimer;
    mapping (uint256=> uint256) beeLastVoted;
    uint256 proposalAmount;
    address proposalRecipient;
    uint32 yesVotes;
    uint32 noVotes;
    uint32 numVotes;
    
    function proposeDistribution(uint256 _beeID, address _recipient, uint256 _amount) public {
        require(proposalTimer != 0, "One at a time");
        // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        require(_amount + 10^16 <= retained);
        proposalTimer = block.timestamp + 604800; // 1 Week to vote.
        yesVotes = 0;
        noVotes = 0;
        numVotes = 0;
        proposalRecipient = _recipient;
        proposalAmount = _amount;
        retained -= (_amount + 10^16); //reserve funds.

    }
    
    function voteDistribution(uint256 _beeID, bool _vote) public payable{
        // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        require(beeLastVoted[_beeID] != proposalTimer, "Double vote");
        beeLastVoted[_beeID] = proposalTimer;
        if (_vote) {
            yesVotes++;
        }else{
            noVotes++;
        }
        numVotes++;
    }
    
    function executeProposal(uint256 _beeID) public payable{
        require(block.timestamp > proposalTimer, "Too soon");
        require(proposalTimer >0, "No proposal");
        proposalTimer = 0; //prevent re-entry
        require(numVotes>100, "less than 100 votes");
        if (yesVotes>noVotes && numVotes > 100){
            // Send the reward
            (bool sent1, bytes memory tmp1) = msg.sender.call{value: 10^16}("");
            require(sent1, "Failed to send Reward");
            //Send the funds
            (bool sent2, bytes memory tmp2) = proposalRecipient.call{value: proposalAmount}("");
            require(sent2, "Failed to send to Recipient");

        }else{
            //restore funds
            retained += proposalAmount + 10^16;
        }

    }
    


    //
    // Governance functions - these are functions that the Governance contract is able to call
    //
    
    function  distributeFunds(uint256 _beeID) public {
        if (treasury >0){ //check for recursion here.
        
            require(treasury >3*10^18, "Less that 3 ETH");  //TODO Don't need this if reward is 0.25%
            require(block.timestamp > nextDistribution, "Too early");
            // TODO FIX this - require(beeNFT.isOwnedBy(_beeID, msg.sender), "Only Bees"); //TODO how do we tell.
        

            uint _reward = 10^16;  // TODO make the reward ~0.25% percentage of the total.
            uint256 _treasury = treasury - _reward;
            treasury = 0; //protect from reentrance by removing any funds.
            
            // Send the reward
            (bool sent1, bytes memory tmp1) = msg.sender.call{value: _reward}("");
            require(sent1, "Failed to send Ether");
            
 
            // take the amount for the DAO.
            uint256 amt = _treasury -_treasury*10000/daoPercent;
            
            //Calculate amount for each hive
            uint256 t = amt/hiveCount;
            
            //Send portion to each hive royalty address.
            for (uint16 i=0; i<hiveCount; i++){
                _treasury -= t;
                (bool sent2, bytes memory tmp2) = reverseHiveMap[i].call{value: t}("");
                require(sent2, "Failed to send Ether");
            }
            retained += _treasury;
        }
    }

/* TODO    
    function addCharity(address _addr) public onlyOwner{
        hiveID[_addr] = hiveNFT.mintToken();
        hiveMap[_addr].balance = 0;
        hivePercent[_addr] = 5; //default
        reverseHiveMap[hiveCount] = _addr;
        hiveCount++;
    }
    
    function setCharityPercent(address _addr, uint8 _p ) public onlyOwner{
        hiveMap[_addr].percent = _p; 
    }
    
    function setDAOPercent(uint8 _p) public onlyOwner{
        daoPercent = _p;
    }
    
*/

}
