# Phylax Credible Layer Sample Assertions

This repository contains a collection of sample assertions for the Phylax Credible Layer. These assertions demonstrate how to prevent various types of vulnerabilities and attacks in smart contracts.

Check out the [official documentation](https://docs.phylax.systems/) to learn more about assertions and the Credible Layer.

To run the tests run the following command:

```
pcl test assertions/test
```

## Previous Hacks

We have collected a list of previous hacks and vulnerabilities and created assertions that would have prevented them.
You can explore them in the [previous hacks](./assertions/previous_hacks/) directory.

## Assertion Categories

### 1. Access Control & Ownership

- [Owner Change](./assertions/src/ass5-owner-change.a.sol): Prevents unauthorized changes to contract ownership and admin roles
- [Implementation Change](./assertions/src/ass1-implementation-change.a.sol): Ensures contract implementation addresses remain unchanged

### 2. Token & Asset Protection

- [ERC20 Drain](./assertions/src/ass20-erc20-drain.a.sol): Prevents unauthorized draining of ERC20 tokens
- [Ether Drain](./assertions/src/ass21-ether-drain.a.sol): Protects against unauthorized ETH withdrawals
- [ERC4626 Protection](./assertions/src/ass12-erc4626-assets-shares.a.sol): Ensures proper accounting in ERC4626 vaults
- [ERC4626 Deposit/Withdraw](./assertions/src/ass13-erc4626-deposit-withdraw.a.sol): Verifies proper deposit and withdrawal operations

### 3. DeFi Protocol Safety

- [Constant Product](./assertions/src/ass6-constant-product.a.sol): Maintains AMM pool invariant
- [Lending Health Factor](./assertions/src/ass7-lending-health-factor.a.sol): Ensures proper collateralization
- [Liquidation Health Factor](./assertions/src/ass16-liquidation-health-factor.a.sol): Prevents unsafe liquidations
- [Positions Sum](./assertions/src/ass8-positions-sum.a.sol): Maintains protocol balance invariants
- [Tokens Borrowed Invariant](./assertions/src/ass19-tokens-borrowed-invariant.a.sol): Ensures proper tracking of borrowed assets

### 4. Oracle & Price Protection

- [Oracle Liveness](./assertions/src/ass10-oracle-liveness.a.sol): Ensures oracle price feeds are active
- [TWAP Deviation](./assertions/src/ass11-twap-deviation.a.sol): Prevents price manipulation
- [Price Within Ticks](./assertions/src/ass15-price-within-ticks.a.sol): Maintains price bounds
- [Intra-TX Oracle Deviation](./assertions/src/ass28-intra-tx-oracle-deviation.a.sol): Prevents oracle manipulation within transactions

### 5. Protocol State Management

- [Timelock Verification](./assertions/src/ass9-timelock-verification.a.sol): Ensures proper timelock delays
- [Panic State Verification](./assertions/src/ass17-panic-state-verificatoin.a.sol): Monitors emergency states
- [Harvest Balance Increase](./assertions/src/ass18-harvest-increases-balance.a.sol): Ensures yield farming operations are profitable
- [Fee Verification](./assertions/src/ass14-fee-verification.a.sol): Maintains proper fee accounting

### 6. Social Protocol Safety

- [Farcaster Message Validity](./assertions/src/ass22-farcaster-message-validity.a.sol): Ensures message integrity in social protocols

## Contributing

If you have suggestions for new assertions or improvements to existing ones, please open a PR or reach out. We're always interested in exploring new use cases and patterns for assertions.
