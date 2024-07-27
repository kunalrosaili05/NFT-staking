// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MockERC20 is Initializable, ERC20Upgradeable {
    function initialize() public initializer {
        __ERC20_init("MockERC20", "MERC");
        _mint(msg.sender, 1000000 * 10**18); 
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
