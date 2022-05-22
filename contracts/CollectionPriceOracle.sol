// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract CollectionPriceOracle is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    mapping(address => uint256) public floors;
    mapping(address => uint256) public movingAvg;

    uint256 public volume;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    event RequestOracle(bytes32 requestId);
    event FulfillRequest(bytes32 requestId, string category, uint256 value);
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
     // chainlink token address
    constructor(address _oracle, bytes32 _jobId, uint256 _fee) {
        setPublicChainlinkToken();
        /* oracle = _oracle;
        jobId = _jobId;
        fee = _fee; */
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 ether; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData(string memory collection) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        //request.add("get", string(abi.encodePacked("https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=", collection))); /* USD */
        request.add("get", "https://morning-shore-50874.herokuapp.com/volume");

        // Set the path to find the desired data in the API response, where the response format is:
        // {
        //      "volume": xxx.xxx,
        // }
        // request.add("path", "RAW.ETH.USD.VOLUME24HOUR"); // Chainlink nodes prior to 1.0.0 support this format
        request.add("path", "volume"); // Chainlink nodes 1.0.0 and later support this format
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);

        emit RequestOracle(requestId);
        return requestId;
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        volume = _volume;
        
        emit FulfillRequest(_requestId, "volume", _volume);
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}