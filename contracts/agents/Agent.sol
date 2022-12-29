// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
//import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IAgent.sol";
import "../AgentRouter.sol";

//import "../lib/Signature.sol";

//import "../tokens/interfaces/IERC721Minimal.sol";

abstract contract Agent is IAgent, ERC721Holder, IERC1271 {
  //using Signature for bytes32;
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  bytes4 internal constant MAGICVALUE = this.isValidSignature.selector;

  uint8 immutable agentId;
  address public immutable AGENT_ROUTER;

  modifier onlyOwner() {
    require(msg.sender == AgentRouter(AGENT_ROUTER).owner(), "Not owner");
    _;
  }

  constructor(uint8 _agentId, address router) {
    agentId = _agentId;
    AGENT_ROUTER = router;
  }

  function getName() external view returns (string memory) {
    return "";
  }

  // supports interface
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == 0x00000000;
  }

  function isValidSignature(bytes32 digest, bytes calldata signature)
    external
    view
    returns (bytes4)
  {
    return MAGICVALUE;
  }
}
