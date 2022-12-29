// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { LeverV1Factory } from "./LeverV1Factory.sol";

// currently only supports collection-wide offers. FIX
// grant permission to transfer assets

/// @notice Offer and balance sheet for lever
contract LeverMarketplace {
  LeverV1Factory factory;
  address owner;
  uint256 royalties;

  // { pool: { tokenId: [0x...] } }
  // mapping(address => mapping(uint256 => bytes32[])) private _offersSheet;
  mapping(address => bytes32[]) private _offerSheet;
  mapping(bytes32 => Offer) private _offers;

  mapping(uint256 => bytes32[]) private _expirations;
  mapping(address => bytes32[]) private _ownerToOffers;

  struct Offer {
    address originator;
    uint256 expiresAt;
    uint256 value;
    bool exists;
  }

  constructor(address _factory, uint256 _royalties) {
    factory = LeverV1Factory(_factory);
    owner = msg.sender;
    royalties = _royalties;
  }

  function createListing() public {
    //
  }

  function placeOffer(address _collection, uint256 contribution) public {
    // require allowance >= amount
    require(contribution > 0);
    Offer memory _offer = new Offer(msg.sender, contribution, true);
    bytes32 storage hashedOffer = keccak256(_offer);

    _offerSheet[_collection].push(hashedOffer);
    _offers[hashedOffer] = _offer;
  }

  function matchForLiquidation(
    address _collection,
    uint256 _minAcceptableAmount
  ) public {}

  function executeMatch(address _collection, bytes32 calldata offer) public {}

  function getHighestOffer(address _collection)
    returns (bytes32 calldata highestHash)
  {
    Offer memory highestOffer;

    for (uint256 i = 0; i < _offerSheet[_collection].length; i++) {
      bytes32 memory currentHash = _offerSheet[_collection][i];
      Offer memory currentOffer = _offers[currentHash];

      if (currentOffer.value > highestOffer.value) {
        highestOffer = currentOffer;
        highestHash = currentHash;
      }
    }
  }

  function cancelOffer() public {}
}
