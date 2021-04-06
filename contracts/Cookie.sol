// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cookie is ERC20 {
    constructor(
        uint256 initialSupply
    ) ERC20('Cookie', 'COOKIE') {
        require(initialSupply > 0, "INITIAL_SUPPLY has to be greater than 0");
        _mint(msg.sender, initialSupply);
    }
}