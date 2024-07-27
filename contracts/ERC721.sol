// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MockNFT is Initializable, ERC721Upgradeable {
    uint256 private _currentTokenId;

    function initialize() public initializer {
        __ERC721_init("MockNFT", "MNFT");
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
