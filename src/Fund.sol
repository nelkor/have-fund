// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDollar is IERC20 {
    function decimals() external view returns (uint8);
}

interface IFundToken is IERC20 {
    function decimals() external view returns (uint8);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract Fund is Ownable {
    bool private _firstTokenMinted;

    bool public isOpen;
    uint128 public price;
    IDollar public dollar;
    IFundToken public immutable fundToken;

    event Closed();
    event Opened(uint128 price);
    event DollarChanged(address newDollar);
    event Sold(address indexed seller, uint256 token, uint256 dollar);
    event Bought(address indexed buyer, uint256 dollar, uint256 token);

    constructor(
        address nativeToken,
        address initialDollar
    ) Ownable(msg.sender) {
        dollar = IDollar(initialDollar);
        fundToken = IFundToken(nativeToken);

        price = 0;
        isOpen = false;
        _firstTokenMinted = false;
    }

    function mintFirstToken() external onlyOwner {
        require(!_firstTokenMinted);

        _firstTokenMinted = true;

        fundToken.mint(address(this), 10 ** 18);
    }

    // Любые erc20-токены, которые отправляют на адрес фонда,
    // можно изъять путём назначения их адреса текущим долларом.
    // Однако, с токеном фонда этот способ не сработает.
    // В случае застревания токенов фонда на адресе фонда их можно сжечь,
    // сохранив на адресе тот самый первый выпущенный токен.
    function burnSurplus() external onlyOwner {
        uint256 surplus = fundToken.balanceOf(address(this)) - 10 ** 18;

        require(!isOpen);
        require(surplus > 0);

        fundToken.burn(address(this), surplus);
    }

    function setDollar(address newDollar) external onlyOwner {
        require(!isOpen);
        require(newDollar != address(fundToken));
        // У долларов decimals может быть разным, но не более 18.
        require(IDollar(newDollar).decimals() <= 18);

        dollar = IDollar(newDollar);

        emit DollarChanged(newDollar);
    }

    function open() external onlyOwner {
        require(!isOpen);
        require(_firstTokenMinted);

        uint256 dollarBalance = dollar.balanceOf(address(this));

        require(dollarBalance > 0);

        // Приводим количество долларов к сумме с 18 decimals.
        uint256 scaledDollarBalance =
            (dollarBalance * 10 ** (18 - dollar.decimals()));

        // Здесь суммы в долларах и в акциях имеют 18 decimals.
        // Если их просто поделить друг на друга, то у цены будет 0 decimals.
        // Чтобы цена была с 18 decimals, умножаем делимое на 1e18.
        uint128 newPrice =
            uint128((scaledDollarBalance * 10 ** 18) / fundToken.totalSupply());

        // Защита от краха фонда,
        // вызванного открытием с ничтожным количеством долларов на счету.
        require(newPrice > price);

        isOpen = true;
        price = newPrice;

        emit Opened(price);
    }

    function close() external onlyOwner {
        require(isOpen);

        isOpen = false;

        dollar.transfer(owner(), dollar.balanceOf(address(this)));

        emit Closed();
    }

    function withdraw() external onlyOwner {
        require(!isOpen);

        dollar.transfer(owner(), dollar.balanceOf(address(this)));
    }

    function sacrifice(uint256 fundTokenAmount) external onlyOwner {
        // Имеет смысл жертвовать только в закрытом состоянии фонда,
        // так как это увеличит цену токена после следующего открытия.
        require(!isOpen);

        fundToken.burn(msg.sender, fundTokenAmount);
    }

    function buy(uint256 dollarAmount) external {
        require(isOpen);
        require(dollarAmount > 0);
        require(dollar.transferFrom(msg.sender, address(this), dollarAmount));

        // Приводим количество долларов к сумме с 18 decimals.
        uint256 scaledDollarAmount =
            (dollarAmount * 10 ** (18 - dollar.decimals()));

        // Поскольку происходит деление на цену с 18 decimals,
        // делимое должно компенсировать это 18 лишними младшими разрядами.
        uint256 fundTokenAmount = (scaledDollarAmount * 10 ** 18) / price;

        fundToken.mint(msg.sender, fundTokenAmount);

        emit Bought(msg.sender, dollarAmount, fundTokenAmount);
    }

    function sell(uint256 fundTokenAmount) external {
        require(isOpen);
        require(fundTokenAmount > 0);

        // Вычисляя количество долларов за токены фонда по текущей цене,
        // получаем сумму, уже приведённую к 18 decimals.
        uint256 scaledDollarAmount = (fundTokenAmount * price) / 10 ** 18;

        // Чтобы отправить правильное количество долларов,
        // надо привести эту сумму к родному decimals токена доллара.
        uint256 dollarAmount =
            (scaledDollarAmount / 10 ** (18 - dollar.decimals()));

        // Если у доллара меньше 18 decimals,
        // слишком маленькое количество токенов фонда будет приводиться к нулю.
        require(dollarAmount > 0);

        fundToken.burn(msg.sender, fundTokenAmount);
        dollar.transfer(msg.sender, dollarAmount);

        emit Sold(msg.sender, fundTokenAmount, dollarAmount);
    }
}
