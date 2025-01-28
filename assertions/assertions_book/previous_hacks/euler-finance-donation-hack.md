# Euler Finance Donation Hack

## Description

The Euler Finance hack exploited two key protocol features:

1. Users could create artificial leverage by minting and depositing assets in the same transaction via `EToken::mint`

2. Users could donate their balance to protocol reserves via `EToken::donateToReserves` without any health checks

The attack worked by:

1. Creating an over-leveraged position by minting excess tokens
2. Donating collateral to intentionally make the position under-collateralized 
3. Self-liquidating the position to take advantage of the 20% liquidation discount

This resulted in the attacker keeping significant "bad debt" while their liquidator account received discounted collateral, profiting from the protocol's liquidation incentives.

**Attack Explanation:**
The attack was executed through two main contracts:

1. Primary Contract:

- Got a 30M DAI flash loan from AAVE V2
- Deployed violator and liquidator contracts
- Sent the DAI to the violator

2. Violator Contract:

- Deposited 20M DAI to get ~19.56M eDAI
- Created artificial leverage twice:
  - First time: Minted ~195.68M eDAI and 200M dDAI
  - Second time: Minted another ~195.68M eDAI and 200M dDAI
- Repaid 10M DAI to reduce dDAI to 190M
- Donated 100M eDAI to reserves

This left the violator with:

- ~310.93M eDAI
- 390M dDAI

The key vulnerability was that the donation created an under-collateralized position (more dDAI than eDAI).

3. Liquidator Contract:

- Liquidated the violator's position
- Due to liquidation discount (20%), got ~310.93M eDAI but only ~259.31M dDAI
- Withdrew DAI by burning eDAI at a favorable rate

The attacker profited ~8.88M DAI (~$8.78M USD) from this attack, with their liquidator contract maintaining a healthy collateralization ratio of ~1.05.

Attack was carried out for several different assets, including DAI, WETH, and USDC.

## Proposed Solution

Proper health checks should be performed on the account that is performing the donation.
Assuming we can check run assertions on each call in the transaction and that we can get all modified accounts in the transaction, we can implement the following assertion:

```solidity
function assertionNoUnsafeDebt() external {
    ph.forkPostState();
    
    // Get all accounts that were modified in this tx
    address[] memory accounts = ph.getModifiedAccounts();
    
    for (uint256 i = 0; i < accounts.length; i++) {
        address account = accounts[i];
        
        uint256 collateral = euler.getAccountCollateral(account);
        uint256 debt = euler.getAccountDebt(account);
        
        // Core invariant: Collateral must always be >= Debt
        // (in practice you'd want some buffer, like 125%)
        require(collateral >= debt, "Account has more debt than collateral");
    }
}
```

This assertion ensures that you don't have more debt than collateral after the transaction.
