// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Auction
 * @dev Implements a auction with bid and refunds.
 */
contract Auction {
    address public owner; // Address of the owner
    address public highestBidder; // Address of highest bidder
    uint256 public highestBid; // Value of the highest bid
    uint256 public auctionEndTime; // Timestamp to end time

    bool public ended; // Indicate if auction has ended

    struct Bid {
        uint256 amount; // Bid amount
        uint256 timestamp; // Timestamp when the bid was made
    }

    mapping(address => Bid[]) public bids; // Stores all bids made by each address
    mapping(address => uint256) public pendingReturns; // Tracks funds to be returned
    address[] public bidders; // Track bidders
    mapping(address => bool) internal hasBid; // Track if bidder is already recorded

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    event Withdrawn(address indexed bidder, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    /**
     * @dev Sets the auction duration from now.
     * @param _durationMinutes Duration of the auction in minutes.
     */
    constructor(uint256 _durationMinutes) {
        require(_durationMinutes > 0);
        owner = msg.sender;
        auctionEndTime = block.timestamp + _durationMinutes;
    }

    /**
     * @dev Allows bidders to place a bid.
     */
    function bid() external payable {
        require(block.timestamp < auctionEndTime);
        require(msg.value > highestBid);

        if (!hasBid[msg.sender]) {
            bidders.push(msg.sender);
            hasBid[msg.sender] = true;
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender].push(Bid({ amount: msg.value, timestamp: block.timestamp }));

        emit NewBid(msg.sender, msg.value);
    }

    /**
     * @dev Ends the auction and announces the winner.
     */
    function endAuction() external {
        require(msg.sender == owner);
        require(block.timestamp >= auctionEndTime);
        require(!ended);

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @dev Refunds Ethers to all non-winning bidders.
     */
    function refundLosingBidders() external {
        require(ended);

        uint256 len = bidders.length;
        address bidder;
        uint256 amount;

        for (uint256 i = 0; i < len; i++) {
            bidder = bidders[i];
            if (bidder != highestBidder) {
                amount = pendingReturns[bidder];
                if (amount > 0) {
                    pendingReturns[bidder] = 0;
                    payable(bidder).transfer(amount);
                    emit Withdrawn(bidder, amount);
                }
            }
        }
    }

    /**
     * @dev Allows bidders withdraw part of their refundable balance.
     * @param _amount Amount to withdraw.
     */
    function partialWithdraw(uint256 _amount) external {
        require(_amount > 0);
        uint256 available = pendingReturns[msg.sender];
        require(available >= _amount);

        pendingReturns[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);

        emit Withdrawn(msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw funds in case of emergency.
     */
    function emergencyWithdraw() external {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(owner).transfer(balance);
        emit EmergencyWithdrawal(owner, balance);
    }

    /**
     * @dev Returns the list of bidders.
     * @return list of bidder addresses.
     */
    function getBidders() external view returns (address[] memory) {
        return bidders;
    }
}