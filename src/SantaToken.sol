// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";

/* 
 * @title SantaToken
 * @notice ERC20 token for SantasList
 * @dev Based on Solmate for extra gas efficiency
 */
contract SantaToken is ERC20 {
    error SantaToken__NotSantasList();

    uint8 private constant DECIMALS = 18;
    address private immutable i_santasList;

    constructor(address santasList) ERC20("SantaToken", "SANTA", DECIMALS) {
        i_santasList = santasList;
    }

    function mint(address to) external {
        if (msg.sender != i_santasList) {
            revert SantaToken__NotSantasList();
        }
        _mint(to, 1e18);
    }

    function burn(address from) external {
        if (msg.sender != i_santasList) {
            revert SantaToken__NotSantasList();
        }
        _burn(from, 1e18);
    }
}
