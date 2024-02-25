// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

contract HelperConfig is Script {
    struct Config {
        uint256 deployKey;
    }

    uint public constant ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    Config public config;

    constructor() {
        if (block.chainid == 11155111) {
            config = getSepoliaConfig();
        } else {
            config = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (Config memory) {
        return Config({
            deployKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilConfig() public pure returns (Config memory) {
        // if (config.deployKey != address(0)) {
        //     return config;
        // }

        return Config({
            deployKey: ANVIL_KEY
        });
    }
}