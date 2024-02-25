// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * Add a time delay to the execution of proposals.
 * Intermediary contract between the governance process and the execution of actions.
 */
contract TimeLock is TimelockController {
    /**
     * @param minDelay initial minimum delay in seconds for operations (how long to wait before executing a proposal)
     * @param proposers accounts to be granted proposer and canceller roles (TODO: update to be anybody)
     * @param executors accounts to be granted executor role (who can execute the proposal after the delay has passed)
     * @param admin optional account to be granted admin role; disable with zero address
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        TimelockController(minDelay, proposers, executors, admin)
    {}
}
