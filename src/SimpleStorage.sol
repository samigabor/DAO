// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleStorage is Ownable {
    uint256 private s_number;

    event NumberChanged(uint256 _number);

    constructor() Ownable(msg.sender) {}

    function setNumber(uint256 _number) public {
        s_number = _number;
        emit NumberChanged(_number);
    }
    
    function getNumber() public view returns (uint256) {
        return s_number;
    }
}
