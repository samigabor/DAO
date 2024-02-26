// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

address constant GOV_TOKEN_ADDRESS_BOB = 0x2F6DF87018866202dE3599608efd145452dF7326;
address payable constant MY_GOVERNOR_ADDRESS_BOB = payable(0x9A60682f3CEf4Db3c5a3c17eB1FD970dB545490A);
address constant TIMELOCK_ADDRESS_BOB = 0xD1cb28091EE8103B2f6224a210d54B1cBC4d0f64;
address constant SIMPLE_STORAGE_ADDRESS_BOB = 0x600172A6E949d5827413B046897a7E0beFD2C797;
uint256 constant PROPOSAL_BOB = 57898217724142283076898486733517586255983963363894930152738103113440309267898;

/**
 forge script script/InteractDAO.s.sol \
  --rpc-url $RPC_URL \
  --broadcast \
  --private-key=$PRIVATE_KEY
 */
contract InteractDAO is Script {
    uint256 constant NUMBER_TO_STORE = 1;

    address[] public targets;
    uint256[] public values;
    bytes[] public calldatas;
    string public description = "Set number to store";

    function run() external {
        mintGovToken(msg.sender, 100 ether);
        uint256 proposalId = proposeSetNumber();
        checkProposalState(proposalId);
        // caseVote(proposalId, 1); // Must wait 1 block to start voting
        // queue(proposalId); // Must wait 10 min until the voting period ends
        // execute(proposalId); // Must wait 5 min until the proposal can be executed
    }

    modifier initDefaultParams {
        targets.push(SIMPLE_STORAGE_ADDRESS_BOB);
        values.push(0);
        calldatas.push(abi.encodeWithSignature("setNumber(uint256)", NUMBER_TO_STORE));
        _;
    }

    function mintGovToken(address user, uint256 amount) public {
        vm.startBroadcast();
        GovToken token = GovToken(GOV_TOKEN_ADDRESS_BOB);
        token.mint(user, amount);
        console.log("Minted %s GovToken to %s", amount, user);
        token.delegate(user);
        console.log("Delegated %s GovToken to myself (%s)", amount, user);
    }

    function proposeSetNumber() public initDefaultParams returns (uint256 proposalId){
        MyGovernor governor = MyGovernor(MY_GOVERNOR_ADDRESS_BOB);
        proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Proposed %s", proposalId);
        console.log("State after proposal: %s", uint256(governor.state(proposalId)));
    }

    function caseVote(uint256 proposalId, uint8 voteType /* { Against, For, Abstain } */) public {
        MyGovernor governor = MyGovernor(MY_GOVERNOR_ADDRESS_BOB);
        governor.castVote(proposalId, voteType);
        console.log("Voted %s on proposal %s", voteType, proposalId);
    }

    function queue(uint256 proposalId) public initDefaultParams {
        MyGovernor governor = MyGovernor(MY_GOVERNOR_ADDRESS_BOB);
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        console.log("Queued proposal %s", proposalId);
    }

    function execute(uint256 proposalId) public initDefaultParams {
        MyGovernor governor = MyGovernor(MY_GOVERNOR_ADDRESS_BOB);
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.execute(targets, values, calldatas, descriptionHash);
        console.log("Executed proposal %s", proposalId);
    }

    function checkProposalState(uint256 proposalId) public view {
        MyGovernor governor = MyGovernor(MY_GOVERNOR_ADDRESS_BOB);
        console.log("State of proposal %s: %s", proposalId, uint256(governor.state(proposalId)));
    }
}
