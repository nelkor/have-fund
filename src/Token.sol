// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract Token is ERC20Permit, Ownable {
    string public tokenURI;

    event TokenURIChanged(string newTokenURI);

    constructor(
        string memory name,
        string memory symbol,
        string memory initialTokenURI
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(msg.sender) {
        tokenURI = initialTokenURI;
    }

    function setTokenURI(string memory uri) external onlyOwner {
        tokenURI = uri;

        emit TokenURIChanged(uri);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
