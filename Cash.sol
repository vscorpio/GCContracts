// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/ERC20PresetFixedSupply.sol

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";


contract Cash is ERC20Burnable {

    constructor() ERC20("$CASH", "$CASH") {
        _mint(msg.sender, 5000000000000000000000000000);
    }
}