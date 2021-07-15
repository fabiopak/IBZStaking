// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC is ERC20 {
    using SafeMath for uint;

    constructor(string memory _nam, string memory _sym, uint _supply) public ERC20(_nam, _sym) {
        _mint(msg.sender, _supply.mul(uint(1e18)));
    }

}