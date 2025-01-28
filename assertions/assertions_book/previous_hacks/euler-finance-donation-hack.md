# Euler Finance Donation Hack

## Description

The Euler Finance protocol permits its users to create artificial leverage by minting and depositing assets in the same transaction via `EToken::mint`. This mechanism permits tokens to be minted that exceed the collateral held by the Euler Finance protocol itself.

The donation mechanism introduced by Euler Finance in eIP-14 (`EToken::donateToReserves`) permits a user to donate their balance to the `reserveBalance` of the token they are transacting with. The flaw lies in that it does not perform any health check on the account that is performing the donation.

As a donation will cause a user’s debt (`DToken`) to remain unchanged while their equity (`EToken`) balance decreases, a liquidation of their account will cause a portion of `DToken` units to remain at the user thus creating bad debt.

The above flaw permits the attacker to create an over-leveraged position and liquidate it themselves in the same block by artificially causing it to go “under-water”.

When the violator liquidates themselves, a percentage-based discount is applied that will cause the liquidator to incur a significant portion of `EToken` units at a discount, guaranteeing that the they will be “above-water” and incur only the debt that matches the collateral they will acquire.

The end result is a violator with a significant amount of “bad debt” (`DToken`) and a liquidator with an over-collateralization of their debt (`DToken > EToken`) due to the percentage-based liquidation incentives the Euler Protocol possesses. As evidenced in the transaction itself, the maximum 20% discount was applied during the attack’s liquidation.

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
