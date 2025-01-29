# Compound Upgrade Bug

## Description

Compound upgraded their comptroller contract to <https://etherscan.io/address/0x374abb8ce19a73f2c4efad642bda76c797f19233> which had a one letter bug on L1217.

The bug occurred when users supplied tokens to markets with zero COMP rewards before initialization. In these cases, the supplyIndex equaled compInitialIndex (1e36), but the reward calculation logic was skipped due to the incorrect comparison operator.

```solidity
if (supplierIndex == 0 && supplyIndex > compInitialIndex) {
    // Covers the case where users supplied tokens before the market's supply state index was set.
    // Rewards the user with COMP accrued from the start of when supplier rewards were first
    // set for the market.
    supplierIndex = compInitialIndex;
}
```

The bug was caused by using > instead of >= in the check. This meant that when supplyIndex equaled compInitialIndex (1e36), the if block was skipped, leaving supplierIndex at 0. The large difference between supplierIndex (0) and supplyIndex (1e36) caused the protocol to pay out massive unintended rewards.

The previous version worked because supplyIndex started at 0 instead of 1e36, though >= would have been more correct.

## Proposed Solution

It would have made sense for the developers to make sure that the COMP accrual increase is within a reasonable bounds.
Having an assertions that checks this in place would have caught the exploit.

In the assertions below, we use the actual Compound distribution rates (0.5 COMP per block) and a maximum of 1000 blocks between distributions (~3.3 hours).
If the COMP accrual increase exceeds the maximum possible rate, the assertion will fail.

```solidity
// Constants for maximum accrual calculations
uint256 public constant COMP_PER_BLOCK = 0.5e18; // 0.5 COMP per block
uint256 public constant MAX_BLOCKS_PER_CALL = 1000; // Max blocks between distributions
uint256 public constant MAX_MARKET_SHARE = 1e18; // 100% of a market (in 1e18 scale)

// the increase should never exceed COMP_PER_BLOCK * MAX_BLOCKS_PER_CALL.
uint256 public constant MAX_INCREASE_PER_CALL = COMP_PER_BLOCK * MAX_BLOCKS_PER_CALL; // 500 COMP

// Verify that COMP accrual increases are within reasonable bounds
function assertionValidCompAccrual() external {
    PhEvm.CallInputs[] memory distributions = ph.getCallInputs(address(compound), DISTRIBUTE_SUPPLIER_COMP);

    for (uint256 i = 0; i < distributions.length; i++) {
        bytes memory data = distributions[i].input;
        (address supplier) = abi.decode(stripSelector(data), (address));

        // Check COMP accrued before and after distribution
        ph.forkCallState(distributions[i]);
        uint256 preAccrued = compound.compAccrued[supplier];

        ph.forkNextCallState(distributions[i]);
        uint256 postAccrued = compound.compAccrued[supplier];

        if (postAccrued > preAccrued) {
            uint256 increase = postAccrued - preAccrued;

            // Maximum increase per call = COMP_PER_BLOCK * MAX_BLOCKS_PER_CALL
            // Uses actual Compound distribution rates (0.5 COMP per block)
            // Assumes a maximum of 1000 blocks between distributions (~3.3 hours)
            // Even if a user has 100% of a market, they can't get more than 500 COMP per call
            // This is a conservative upper bound that would have caught the exploit while allowing legitimate distributions
            require(increase <= MAX_INCREASE_PER_CALL, "COMP accrual increase exceeds maximum possible rate");
        }
    }
}
```
