# Auction Smart Contract

## Overview

This is a Solidity smart contract that implements a simple auction system with incremental bidding and partial refunds. Users can place bids that must be higher than the previous bid plus a fixed percentage increase. The auction duration can be extended if a bid is placed near the end time. The contract also handles commission fees and refunds for non-winning bidders.

---

## Features

- Incremental bidding with a minimum increase percentage.
- Auction duration extension if bids are placed near the end.
- Partial refunds for bidders who have been outbid.
- Owner commission on refunded amounts.
- Public getters for winner and all bids.
- Only the owner can finalize the auction and withdraw funds.

---

## Contract Details

### Constants

| Constant                     | Description                                                    |
|------------------------------|----------------------------------------------------------------|
| `AUCTION_EXTENSION_DURATION` | Time extension (10 minutes) if a bid is placed near auction end |
| `AUCTION_INITIAL_DURATION`   | Initial auction duration (24 hours)                            |
| `PRICE_INCREMENT_PERCENTAGE` | Minimum percentage increment required for a new bid (5%)      |
| `OWNER_COMMISSION_PERCENTAGE`| Commission fee percentage taken by owner on refunds (2%)      |

### State Variables

| Variable         | Description                         |
|------------------|-----------------------------------|
| `owner`          | Address of the contract owner     |
| `minPriceToBid`  | Minimum bid amount allowed         |
| `endTime`        | Timestamp when auction ends        |
| `historicBids`   | Array storing all bids made        |
| `winner`         | The current winning bid            |

### Mappings

| Mapping        | Description                                         |
|----------------|----------------------------------------------------|
| `bids`         | Last bid amount placed by each participant         |
| `deposits`     | Total amount deposited by each participant         |
| `refunded`     | Flags indicating if a participant has been refunded|

---

## Events

- **`NewBid (bidder, amount, timestamp)`**
Emitted when a new bid is placed
  - `bidder` — address of bidder
  - `amount` —  amount of the bid
  - `timestamp` —  time when bid is placed

- **`AuctionEnded (winner, winningBid, timestamp)`**
Emitted when the auction ends and winner is declared.
  - `winner` — address of winner
  - `winningBid` —  amount of the winner bid
  - `timestamp` —  time when bid is placed

---

## Modifiers

- `onlyOwner`  
  Restricts function calls to only the contract owner.

- `auctionActive`  
  Ensures the auction is still running.

- `auctionInactive`  
  Ensures the auction has ended.

---

## Functions

- **`constructor()`**
  Sets the deployer as the owner, the minimum bid price to 1 and sets auction end time to current time + 24 hours.

- **`placeBid()`**  
  Place the bid only if it is bigger than the minimum amount to bid.
  
  - Emits `NewBid` event.
  - Extends the auction end time if necessary.

- **`withdrawPartial()`**  
  Returns the amount of old bids to bidder.

  - Only callable while the auction is active.

- **`finalizeAuction()`**  
  Ends the auction and transfers the winning amount to the owner. Refunds the other bidders (minus commission).

  - Emits `AuctionEnded` event.
  - Only callable by the owner after the auction ends.
 
- **`isAuctionActive()`**  
  Returns true if the auction is still active, else false.

