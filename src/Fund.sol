// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDollar is IERC20 {
    function decimals() external view returns (uint8);
}

interface IFundToken is IERC20 {
    function decimals() external view returns (uint8);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function setTokenURI(string calldata newURI) external;
}

contract Fund is Ownable {
    bool private _firstTokenMinted;

    bool public isOpen;
    uint128 public price;
    IDollar public dollar;
    IFundToken public immutable fundToken;

    event Opened();
    event Closed();
    event dollarChanged(address oldDollar, address newDollar);
    event Sold(address indexed seller, uint256 token, uint256 dollar);
    event Bought(address indexed buyer, uint256 dollar, uint256 token);

    constructor(
        address initialToken,
        address initialDollar
    ) Ownable(msg.sender) {
        dollar = IDollar(initialDollar);
        fundToken = IFundToken(initialToken);

        isOpen = false;
        _firstTokenMinted = false;
    }

    function mintFirstToken() external onlyOwner {
        require(!_firstTokenMinted);

        _firstTokenMinted = true;

        fundToken.mint(address(this), 10 ** 18);
    }

    function setDollar(address newDollar) external onlyOwner {
        require(!isOpen);
        require(newDollar != address(fundToken));
        require(IDollar(newDollar).decimals() <= 18);

        address oldDollar = address(dollar);

        dollar = IDollar(newDollar);

        emit dollarChanged(oldDollar, newDollar);
    }

    function setTokenURI(string calldata uri) external onlyOwner {
        fundToken.setTokenURI(uri);
    }

    function open() external onlyOwner {
        require(!isOpen);
        require(_firstTokenMinted);

        uint256 dollarBalance = dollar.balanceOf(address(this));

        require(dollarBalance > 0);

        uint256 scaledDollarBalance =
            (dollarBalance * 10 ** (18 - dollar.decimals()));

        isOpen = true;
        price = uint128(scaledDollarBalance / fundToken.totalSupply());

        emit Opened();
    }

    function close() external onlyOwner {
        require(isOpen);

        price = 0;
        isOpen = false;

        emit Closed();
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(!isOpen);

        dollar.transfer(owner(), amount);
    }

    function buy(uint256 dollarAmount) external {
        require(isOpen);
        require(dollarAmount > 0);
        require(dollar.transferFrom(msg.sender, address(this), dollarAmount));

        uint256 fundTokenAmount = (dollarAmount * 10 ** 18) / price;

        fundToken.mint(msg.sender, fundTokenAmount);

        emit Bought(msg.sender, dollarAmount, fundTokenAmount);
    }

    function sell(uint256 fundTokenAmount) external {
        require(isOpen);
        require(fundTokenAmount > 0);

        uint256 dollarAmount = (fundTokenAmount * price) / 10 ** 18;

        dollar.transfer(msg.sender, dollarAmount);
        fundToken.burn(msg.sender, fundTokenAmount);

        emit Sold(msg.sender, fundTokenAmount, dollarAmount);
    }
}
