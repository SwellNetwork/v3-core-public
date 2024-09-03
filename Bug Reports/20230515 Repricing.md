# 20230515 Repricing [DRAFT]

Severity: Low

Discovered By: Swell Labs

## Issue

- The total rewards earned by the Swell protocol since the previous repricing event determines the fees to be minted to the Node Operators and Swell treasury
- Total rewards earned depend on the delta in the total ETH staked between the previous repricing event and the current repricing event
- Repricing events are calculated off-chain with respect to a given block/slot (aligned such that the slot produced the block)
- There is no on-chain mechanism to know the total ETH staked at the previous repricing event

## Impact

- A reprice transaction was submitted to the blockchain in error
    - [https://etherscan.io/tx/0x8c15d0602e0542fae64fe53c6255e01a5a935e95a7f3f1be4d3a7f2b36c6d904](https://etherscan.io/tx/0x8c15d0602e0542fae64fe53c6255e01a5a935e95a7f3f1be4d3a7f2b36c6d904)
- An incorrect newETHRewards and preRewardETHReserves value was sent to the contract
- The sum of newETHRewards and preRewardETHReserves was correct
    - The swETH/ETH repricing value set was correctly
- As Swell is operating with zero fees, this did not affect the minting of rewards
    - No direct remediation is required at this stage to offset any on-chain effect
- Third parties who rely on this value may be misled by the errant value
- A smart contract upgrade will be performed to remediate this issue
