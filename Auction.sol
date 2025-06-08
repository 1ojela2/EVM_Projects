// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Auction {
    address public owner; // Address of the contract owner
    address public highestBidder; // Address of highest bidder
    uint256 public highestBid; // Value of the highest bid
    uint256 public auctionEndTime; // Timestamp to end time

    constructor(uint256 _durationMinutes) {
        owner = msg.sender; // Set the contract creator as the owner
        auctionEndTime = block.timestamp + _durationMinutes; // Set auction duration from now
    }

    bool public ended; // Flag to indicate if auction has ended

    struct Bid {
        uint256 amount; // Bid amount
        uint256 timestamp; // Timestamp when the bid was made
    }

    mapping(address => Bid[]) public bids; // Stores all bids made by each address
    mapping(address => uint256) public pendingReturns; // Tracks funds to be returned

    event NewBid(address indexed bidder, uint256 amount); // Emitted when a new valid bid is placed
    event AuctionEnded(address winner, uint256 amount); // Emitted when the auction ends

    modifier onlyOwner() {
        require(msg.sender == owner); // Restrict access to contract owner
        _;
    }

    modifier auctionActive() {
        require(block.timestamp < auctionEndTime); // Only allow if auction is still ongoing
        _;
    }

    modifier auctionEnded() {
        require(block.timestamp >= auctionEndTime); // Only allow if auction time has passed
        _;
    }

    function bid() external payable auctionActive {
        // Function to place a bid during an active auction
        require(msg.value > 0); // Must send a positive amount
        uint256 minBid = (highestBid * 105) / 100; // Calculate 105% of the current highest bid
        require(msg.value > minBid); // Require bid to be higher than 105% of current highest

        if (msg.sender != highestBidder) {
            pendingReturns[msg.sender] += msg.value; // Add to pending returns if not the highest bidder
        }

        bids[msg.sender].push(Bid(msg.value, block.timestamp)); // Save the bid with timestamp

        highestBidder = msg.sender; // Update the current highest bidder
        highestBid = msg.value; // Update the current highest bid

        if (auctionEndTime - block.timestamp <= 10 minutes) {
            auctionEndTime += 10 minutes; // Extend auction time if close to ending
        }

        emit NewBid(msg.sender, msg.value); // Emit event for new bid
    }

    function endAuction() external auctionEnded {
        // Function to officially end the auction
        require(!ended); // Ensure auction hasn't already ended
        ended = true;
        emit AuctionEnded(highestBidder, highestBid); // Emit auction ended event
    }

    function claimFunds() external auctionEnded {
        // Function for bidders (excluding winner) to reclaim funds
        require(msg.sender != highestBidder); // Winner cannot claim back funds

        uint256 amount = 0;
        for (uint256 i = 0; i < bids[msg.sender].length; i++) {
            amount += bids[msg.sender][i].amount; // Sum up all bids by the sender
        }

        require(amount > 0); // Ensure there's something to refund

        uint256 refund = amount - (amount * 2) / 100; // Apply a 2% fee before refunding

        payable(msg.sender).transfer(refund); // Transfer the refund
    }

    function getWinner() external view auctionEnded returns (address, uint256) {
        // View function to return the winner and highest bid
        return (highestBidder, highestBid);
    }

    function getOffers(address user) external view returns (Bid[] memory) {
        // View function to get all bids made by a specific user
        return bids[user];
    }
}
