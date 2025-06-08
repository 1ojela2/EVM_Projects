# EVM_Projects
learning solidity and smart contracts

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Project 1:

This smart contract, written in Solidity under the MIT license, implements an auction.

This auction is for a fixed time, which must be defined before deploying the contract.
To win the auction, the winning bidder must have the best bid in the last 10 minutes. If a better bid is made, the timer resets for 10 more minutes.

Only the winner can withdraw the prize, and the other bidders will receive their auctioned ETH, minus a 2% auction management fee.

The implementation is Auction.sol

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
