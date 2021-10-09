// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// -------------
// FANCY BEE DAO
//
// This DAO esponsible for managing the treasury and NFT other contracts:
//  - BeeNFTs, 
//  - OutfitNFTs
//
// The DAO is also a container that manages Hives (charitable organisations)
//
//
// All operations that involve a royalty to the DAO must be mediated
// thought this contract.
//
// The DAO is goverened though voting, where each bee has a vote

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

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

import "./Royalty.sol";
//import "./BeeNFT.sol";
//import "./OutfitNFT.sol";
    
contract FancyBDAO is Ownable {
    
    BeeNFT public beeNFT;
    OutfitNFT public outfitNFT; 

    uint256 public treasury;        // Amount to be distributed
    uint256 public retained;        // Amount held for DAO
    uint256 public daoPercent;      // % to be retained by DAO (as basispoint i.e. x 100)
    uint256 public nextDistribution; // Timer to prevent high gas fees
    uint32 public distributionInterval = 604800;
    
    
    constructor(){
        //Create NFTs controlled by the DAO (but not owned)
        beeNFT = new BeeNFT();
        beeNFT.transferOwnership(msg.sender);
        outfitNFT = new OutfitNFT();
        outfitNFT.transferOwnership(msg.sender);
      
        nextDistribution = block.timestamp + distributionInterval; 
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
    // voting and Governance
    //

    uint256 public proposalTimer;
    mapping (uint256=> uint256) beeLastVoted;
    uint256 public proposalAmount;
    address public proposalRecipient;
    uint32 public yesVotes;
    uint32 public noVotes;
    uint32 public numVotes;
    uint8 public threshold;
    uint8 public duration;
    
    function proposeDistribution(
        uint256 _beeID, 
        address _recipient, 
        uint256 _amount,
        uint8 _days,        // length of the poll
        uint8 _threshold    //percentage required
        ) public {
        require(proposalTimer != 0, "One at a time");
        require(beeNFT.ownerOf(_beeID) == msg.sender, "Only Bees can propose");
        require(_amount + 10^16 <= retained);
        require(_days > 0, "Must be more than 1 day");
        require(_threshold <100, "Must be l;ess than 100%");
        proposalTimer = block.timestamp + _days * 8640; // Seconds in a day
        yesVotes = 0;
        noVotes = 0;
        numVotes = 0;
        proposalRecipient = _recipient;
        proposalAmount = _amount;
        duration = _days;
        threshold = _threshold;
        retained -= (_amount + 10^16); //reserve funds.

    }
    
    function voteDistribution(uint256 _beeID, bool _vote) public payable{
        require(beeNFT.ownerOf(_beeID) == msg.sender, "Only Bees can vote");
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
        require(beeNFT.ownerOf(_beeID) == msg.sender, "Only Bees can trigger execution");
        require(block.timestamp > proposalTimer, "Too soon");
        require(numVotes>100, "less than 100 votes");
        require(proposalTimer >0, "No proposal"); //trap re-entry
        proposalTimer = 0; //prevent re-entry
        
        // Send the reward to Bee
        (bool sent1, bytes memory tmp1) = msg.sender.call{value: 10^16}("");
        require(sent1, "Failed to send Reward");
        
        if (yesVotes>(yesVotes+noVotes)*threshold/100){
            // Send the funds in the proposal
            (bool sent2, bytes memory tmp2) = proposalRecipient.call{value: proposalAmount}("");
            require(sent2, "Failed to send to Recipient");
        }else{
            //restore funds
            retained += proposalAmount + 10^16;
        }
    }
    
    //
    //HIVES
    //
    
    // Hives are indexed by uint32 hiveID
    mapping (uint32=> uint256) public hiveBalance;
    mapping (uint32=> uint8) public hiveRatio;
    mapping (uint32=> address) public hiveOwner;
    
    // Addresses can only have one hive.
    mapping (address=> uint32) public hiveID;
    
    uint32 public hiveCount = 0; //number of active hives
    uint32 public hiveSlot = 0; //last assigned hive ID (does not re-use IDs)

    //Currently can only be added by the owner of the DAO conract.
    //TODO need to make this a governance thing
    function addHive(address _addr) public onlyOwner returns (uint32){
        require(hiveID[_addr] == 0, "One hive per address");
        require(hiveCount < 1000, "Only 1000 hives allowed");
        hiveSlot++;
        hiveCount++;
        hiveOwner[hiveSlot] = _addr;
        hiveBalance[hiveSlot] = 0;
        hiveRatio[hiveSlot] = 10; // this is a divisor * 10 (unused for now)
        hiveID[_addr] = hiveSlot; //Starts at 1
        return(hiveSlot);

    }
    
    function removeHive(uint32 _hive) public onlyOwner{
        require(hiveRatio[_hive] !=0, "Hive doesn't exist");
        hiveRatio[_hive] = 0; // Cannot be Zero so Zero means no hive.  
        hiveID[hiveOwner[_hive]] = 0;
        hiveOwner[_hive] = address(0);
        hiveRatio[_hive] = 0;
        hiveBalance[_hive] = 0;
        hiveCount--;
    }
    function setCharityRatio(uint32 _hive, uint8 _p ) public onlyOwner{
        require(hiveRatio[_hive] !=0, "Hive doesn't exist");   
        require(_p >0 && _p<11, "Ratio arg must be 1-10");
        hiveRatio[_hive] = _p; 
    }
    
    function setDAOPercent(uint16 _p) public onlyOwner{
        require(_p<10000, "Cannot be greater than 100%");
        daoPercent = _p;
    }
    
    // 
    // Called by any bee for a small reward.
    // Must have a significant balance and more then a week appart
    //
    function  distributeFunds(uint256 _beeID) public {

        if (treasury >0){ //check for recursion here. treasury is set to 0 until we know remainder
        
            require(beeNFT.ownerOf(_beeID) == msg.sender, "Only Bees can trigger distribution");
            require(treasury >3*10^18, "Less that 3 ETH");  //TODO Don't need this if reward is 0.25%
            require(block.timestamp > nextDistribution, "Too early");
            
            nextDistribution = block.timestamp + distributionInterval; // update interval
        
            uint _reward = 10^16;  // TODO make the reward ~0.25% percentage of the total.
            uint256 _treasury = treasury - _reward;
            treasury = 0; //protect from reentrance by removing any funds.
            
            // Send the reward
            (bool sent1, bytes memory tmp1) = msg.sender.call{value: _reward}("");
            require(sent1, "Failed to send Ether");
 
            // reserve the amount for the DAO.
            uint256 amt = _treasury -(_treasury*daoPercent)/10000;
            
            // Calculate allocation for each hive
            // TODO use the ratio. This assumes equality
            uint256 _alloc = amt/hiveCount;
            
            //Send portion to each hive royalty address.
            for (uint16 i=1; i<=hiveCount; i++){
                if (hiveRatio[i] !=0){ //Ignore deleted hives
                    _treasury -= _alloc;
                    (bool sent2, bytes memory tmp2) = hiveOwner[i].call{value: _alloc}("");
                    require(sent2, "Failed to send Ether");
                }
            }
            retained += _treasury; //Move the remainder into the retained funds
        }
    }
}
