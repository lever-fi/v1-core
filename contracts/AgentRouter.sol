// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./tokens/interfaces/IERC721Minimal.sol";
import "./agents/IAgent.sol";
import "./interfaces/ILeverV1Factory.sol";

contract AgentRouter {
  address public immutable factory;
  mapping(uint8 => address) public agents;

  address public owner;

  event SetAgent(uint8 id, string name, address indexed location);

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyPool() {
    require(
      ILeverV1Factory(factory).isValidPool(msg.sender),
      "Sender must be pool"
    );
    _;
  }

  constructor(address _factory) {
    owner = msg.sender;
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
    return
      IAgent(agents[agentId]).purchase{ value: msg.value }(msg.sender, data);
    // (bool txnSuccess, bytes memory _data) = agents[agentId].delegatecall(
    //   abi.encodeWithSignature("purchase(bytes)", data)
    // );
    // (bool fnSuccess, address collection, uint256 tokenId) = abi.decode(
    //   _data,
    //   (bool, address, uint256)
    // );

    // IERC721Minimal(collection).safeTransferFrom(
    //   address(this),
    //   msg.sender,
    //   tokenId
    // );

    //return txnSuccess && fnSuccess;
  }

  // function setApprovalForAll(
  //   address operator,
  //   address collection,
  //   bool state
  // ) external onlyOwner {
  //   IERC721Minimal(collection).setApprovalForAll(operator, state);
  // }
}
