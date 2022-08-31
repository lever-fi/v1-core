// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./pool/ILeverV1PoolActions.sol";
import "./pool/ILeverV1PoolOwnerActions.sol";
import "./pool/ILeverV1PoolErrors.sol";
import "./pool/ILeverV1PoolEvents.sol";
import "./pool/ILeverV1PoolState.sol";
import "./pool/ILeverV1PoolImmutables.sol";

interface ILeverV1Pool is
  ILeverV1PoolActions,
  ILeverV1PoolOwnerActions,
  ILeverV1PoolErrors,
  ILeverV1PoolEvents,
  ILeverV1PoolState,
  ILeverV1PoolImmutables
{}
