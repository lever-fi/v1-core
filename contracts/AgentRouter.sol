// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IAgent.sol";
import "./interfaces/ILeverV1Factory.sol";

contract AgentRouter {
  address immutable factory;
  mapping(uint8 => address) public agents;

  address public owner;

  event SetAgent(uint8 id, string name, address indexed location);
  // require pool to be valid lever pool

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyPool() {
    require(ILeverV1Factory(factory).isValidPool(msg.sender), "Sender be pool");
    _;
  }

  constructor(address _factory) {
    factory = _factory;
  }

  function setAgent(
    uint8 agentId,
    string memory agentName,
    address location
  ) external onlyOwner {
    require(IAgent(location).supportsInterface(0x00000000));
    agents[agentId] = location;
    emit SetAgent(agentId, agentName, location);
  }

  function purchase(uint8 agentId, bytes calldata data)
    external
    payable
    onlyPool
    returns (bool)
  {
    require(agents[agentId] != address(0), "Invalid agent");

    (bool success, ) = agents[agentId].delegatecall(
      abi.encodeWithSignature("purchase(bytes)", data)
    );

    return success;
  }
}
