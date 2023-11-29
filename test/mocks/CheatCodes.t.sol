// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface _CheatCodes {
    function ffi(string[] calldata) external returns (bytes memory);
}
