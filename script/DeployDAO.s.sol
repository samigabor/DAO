// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDAO is Script {
    uint256 public constant MIN_DELAY = 300; // 5 min - delay until a proposal can be executed once it has passed
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    GovToken govToken;
    TimeLock timelock;
    MyGovernor governor;
    SimpleStorage simpleStorage;

    address[] public proposers; // empty means anybody can propose
    address[] public executors; // empty means anybody can execute

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;

    /**
        forge script script/DeployDAO.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

        forge script script/DeployDAO.s.sol \
        --rpc-url $RPC_URL \
        --broadcast \
        --private-key=$PRIVATE_KEY \
        --verify --etherscan-api-key $ETHERSCAN_API_KEY
     */
    function run() external returns (GovToken, TimeLock, MyGovernor, SimpleStorage, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        uint256 deployerKey = helperConfig.config();

        vm.startBroadcast(deployerKey);
        govToken = new GovToken();
        govToken.mint(msg.sender, INITIAL_SUPPLY);
        timelock = new TimeLock(MIN_DELAY, proposers, executors, address(0));
        governor = new MyGovernor(govToken, timelock);
        simpleStorage = new SimpleStorage();
        return (govToken, timelock, governor, simpleStorage, helperConfig);
    }
}
