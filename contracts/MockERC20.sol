pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("ABC", "abc") {
        _mint(msg.sender, 100_000_000_000 * 10 ** 18);
    }
}