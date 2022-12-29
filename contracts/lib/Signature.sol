// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Signature {
  // function recoverSigner(bytes32 _hash, bytes memory _signature)
  //   internal
  //   pure
  //   returns (address signer)
  // {
  //   require(
  //     _signature.length == 65,
  //     "SignatureValidator#recoverSigner: invalid signature length"
  //   );
  //   // Variables are not scoped in Solidity.
  //   uint8 v = uint8(_signature[64]);
  //   bytes32 r = _signature.readBytes32(0);
  //   bytes32 s = _signature.readBytes32(32);
  //   // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
  //   // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
  //   // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
  //   // signatures from current libraries generate a unique signature with an s-value in the lower half order.
  //   //
  //   // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
  //   // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
  //   // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
  //   // these malleable signatures as well.
  //   //
  //   // Source OpenZeppelin
  //   // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
  //   if (
  //     uint256(s) >
  //     0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
  //   ) {
  //     revert("SignatureValidator#recoverSigner: invalid signature 's' value");
  //   }
  //   if (v != 27 && v != 28) {
  //     revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
  //   }
  //   // Recover ECDSA signer
  //   signer = ecrecover(
  //     keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
  //     v,
  //     r,
  //     s
  //   );
  //   // Prevent signer from being 0x0
  //   require(
  //     signer != address(0x0),
  //     "SignatureValidator#recoverSigner: INVALID_SIGNER"
  //   );
  //   return signer;
  // }
}
