// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;


/// @title Auction
/// @author Wayar Matias Nahuel
/// @notice This contract implements an auction where users can bid with increasing offers
/// @dev Implements required events and partial refunds. Winner and Bids are public so they have it's defaults getters
contract Auction {
    // Configuracion constants

    /// @notice time to extend the auction if the bid is placed when its almost finished
    uint256 private constant AUCTION_EXTENSION_DURATION = 10 minutes;  
    /// @notice duration of the auction
    uint256 private constant AUCTION_INITIAL_DURATION = 24 hours;  
    /// @notice percentage of increment appicable for bids
    uint256 private constant PRICE_INCREMENT_PERCENTAGE = 5;    
    /// @notice percentage of commision        
    uint256 private constant OWNER_COMMISSION_PERCENTAGE = 2;

    // Variables

    /// @notice address of the contract owner
    address public owner;
    /// @notice min price to place a bid
    uint256 public minPriceToBid;
    /// @notice auction end time
    uint256 public endTime;

    /// @notice struct that represents a bid
    struct Bid {
        address bidder;
        uint256 amount;
    }

    /// @dev last bid of each participant
    mapping(address => uint256) private bids;
    /// @dev all amount placed of each participant
    mapping(address => uint256) private deposits;
    /// @dev flag to check if the participant has been refunded or not (only at the end of the auction)
    mapping(address => bool) private refunded;

    /// @notice all bids placed, public so can be used the default getter
    Bid[] public historicBids;
    /// @notice winner of the auction, public so can be used the default getter
    Bid public winner;

    // Events

    /// @notice Emitted when new bid is placed
    /// @param bidder address of bidder
    /// @param amount amount of the bid
    /// @param timestamp time when bid is placed
    event NewBid(address indexed bidder, uint256 amount, uint256 timestamp);

    /// @notice Emitted when the auction is finished
    /// @param winner address of the winner
    /// @param winningBid amount of the winner bid
    /// @param timestamp time when auction is concluded
    event AuctionEnded(address indexed winner, uint256 winningBid, uint256 timestamp);

    // Modificators

    /// @dev Restricts the execution of the functions only for the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this!");
        _;
    }

    /// @dev Restricts the execution of the functions only when the auction is alive
    modifier auctionActive() {
        require(block.timestamp <= endTime, "Auction is not active!");
        _;
    }

    /// @dev Restricts the execution of the functions only when the auction has finished
    modifier auctionInactive() {
        require(block.timestamp > endTime, "Auction is alive!");
        _;
    }


    /// @notice Constructor that initialize the auction
    /// @dev sets the owner, the initial min price to bid and the auction end time
    constructor () {
        owner = msg.sender;
        minPriceToBid = 1;
        endTime = block.timestamp + AUCTION_INITIAL_DURATION;
    }

    /// @notice Place the bid only if its bigger than the min amount to bid
    /// @dev only can be called while the auction is alive
    /// @dev increments the min price to bid by PRICE_INCREMENT_PERCENTAGE
    /// @dev if the bid is placed in the last AUCTION_EXTENSION_DURATION minutes, is extended by AUCTION_EXTENSION_DURATION
    /// @dev emits the event {NewBid}
    function placeBid() external payable auctionActive {
        require(msg.value > minPriceToBid, "Bids must be bigger than the min price to bid");

        winner = Bid(msg.sender, msg.value);
        historicBids.push(winner);
        minPriceToBid = msg.value * (100 + PRICE_INCREMENT_PERCENTAGE) / 100;
        
        bids[msg.sender] = msg.value;
        deposits[msg.sender] += msg.value;

        if (endTime - block.timestamp <= AUCTION_EXTENSION_DURATION) {
            endTime += AUCTION_EXTENSION_DURATION;
        }

        emit NewBid(winner.bidder, winner.amount, block.timestamp);
    }

    /// @notice Returns the amount of old bids to bidder
    /// @dev only can be called while the auction is alive
    function withdrawPartial() external auctionActive{
        uint256 withdrawable = deposits[msg.sender] - bids[msg.sender];
        require(withdrawable > 0, "Nothing to withdraw");

        deposits[msg.sender] -= withdrawable;

        (bool success, ) = payable(msg.sender).call{value: withdrawable}("");
        require(success, "Transfer failed");
    }

    /// @notice Ends the auction and transfer the winner amount to the owner, and the bids to the bidders applying a custom fee
    /// @dev only owner can execute the method and only if the auction is ended
    /// @dev emits the event {AuctionEnded}
    function finalizeAuction() external onlyOwner auctionInactive {
        uint256 winningAmount = winner.amount;
        require(winningAmount > 0, "No winner");

        (bool ownerSuccess, ) = payable(owner).call{value: winningAmount}("");
        require(ownerSuccess, "Owner transfer failed");

        emit AuctionEnded(winner.bidder, winningAmount, block.timestamp);

        uint256 _bidsLength = historicBids.length;

        for (uint256 i = 0 ; i < _bidsLength; i++) {
            address bidder = historicBids[i].bidder;

            if (bidder == winner.bidder || refunded[bidder]) {
                continue;
            }

            uint256 withdrawable = deposits[bidder];
            if (withdrawable > 0 ){
                uint256 fee = (withdrawable * OWNER_COMMISSION_PERCENTAGE) / 100;
                uint256 amountToSend = withdrawable - fee;
                deposits[bidder] = 0;
                refunded[bidder] = true;

                (bool success, ) = payable(bidder).call{value: amountToSend}("");
                require(success, "Refund transfer failed");            
            }            
        }
    }

    /// @notice indicates if the auction is still active
    /// @return true or false depending on auction status
    function isAuctionActive() public view returns (bool) {
        return block.timestamp <= endTime;
    }
}