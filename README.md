# Phylax Credible Layer Sample Assertions

This is a collection of sample assertions for the Phylax Credible Layer.

Currently it's in a very early stage since syntax for assertions is not yet finalized.

The repo contains some example assertions in a syntax that could be somewhat close the the final one.

There's no way to run the assertions yet, but the README will be updated once there's a way to test them out.

## Covered Hack Families
We try to cover as many different types of hacks as possible that could be prevented using assertions.
Naturally not all hack types can be prevented using assertions.
Below we list some of the hack families where assertions can be useful:

### Ownership
We have seen a lot of hacks where the attacker has taken over the ownership of a contract recently.
A straight forward way to prevent this is to assert that ownership doesn't change.
If the owner(s) want to change the ownership they should plan this ahead of time and pause the assertions first.
Some examples of how these assertions look is in the [LendingPoolAddressesProviderAssertions.sol](./assertion/LendingPoolAddressesProviderAssertions.sol), the [AerodromePoolFactoryAssertions.sol](./assertion/AerodromePoolFactoryAssertions.sol) file and the [AerodromeVoterAssertions.sol](./assertion/AerodromeVoterAssertions.sol) file.

### Token Drain
Similarly a lot of hacks have been done by draining tokens from a contract.
A somewhat naive way to prevent this is to assert the balance of a monitored contract never goes to 0 in one transaction or that the balance never goes below a certain threshold in one transaction.
Hackers will probably just drain up to the threshold, but at least some damage control takes place and it might prevent some attacks all together.
Some examples of how these assertions look is in the [ERC20Assertions.sol](./assertion/ERC20Assertions.sol) file. Similarly to ERC20 drains, there are also some Ether examples in the [EtherBalanceAssertions.sol](./assertion/EtherBalanceAssertions.sol) file.

### Approval Vulnerabilities
Quite often people lose tokens because they're scammed into giving full approval to a bad actor or because they've set a high allowance to some legit dapp that then got hacked.
Many of these cases could be prevented by checking that only certain addresses have allowance and that the allowance is not above a certain threshold.
Some examples of how these assertions look is in the [ERC20Assertions.sol](./assertion/ERC20Assertions.sol) file.

### Griefing
Griefing attacks are not as common as some of the other hack types we mention, but we still think it's useful to be able to assert that griefing doesn't happen.
Currently we'd need a cheatcode that allows the Credible Layer to check who the caller of a function is in order to be able to only allow certain addresses to call a function.
There's a simple example of how this could look in the [GriefingAssertion.sol](./assertion/GriefingAssertion.sol) file.

### Multisig Configuration
Multisigs hold large amount of funds and are used to make important protocol changes and upgrades these days.
It's important that the multisig configurations are sane and that they stay that way. For example making sure that the amount of signatures required isn't lowered all of a sudden or make sure that the nonce actually increases for each transaction.
Luckily we haven't seen any hacks or funds lost caused by bugs in the Safe contracts themselves lately, but it's better to be safe than sorry.
Some examples of some assertions can be found in the [SafeAssertions.sol](./assertion/SafeAssertions.sol) file.

### DAO Configuration
Similar to multisigs DAOs also hold large amounts of funds and are used to make important protocol changes and upgrades.
Because of that it's important that the DAO configurations are sane and that they stay that way.
There hasn't been any hacks caused by bugs in the Moloch v3 contracts themselves, but with bad configuration it's possible to have a hostile take over or DoS attacks.
Some examples of some assertions can be found in the [BaalMolochv3Assertions.sol](./assertion/BaalMolochv3Assertions.sol) file.

## Hack Families Not Covered
Not all hack types can be prevented using assertions and some still require some research and potentially more features to the Credible Layer, before assertions can be useful.
Below we list some of the hack types that are not covered yet:

### Front-Running
Assertions can't prevent front-running attacks, since there's no way to know how the block builder will build the block.
The Credible Layer might help prevent these attacks though, since we incentive block builder / assertions enforcers to behave as expected to avoid slashing.

### Oracle Manipulation
It's very complicated to write assertions that can prevent oracle manipulation. Even with access to the oracle prices it's hard to know if the prices are manipulated or not. Especially, it's hard to distinguish whales from potential flash loans or other ways of manipulating the price.
If protocols define some thresholds for the price swings they consider "safe" it might be possible to write assertions for that.

### Reentrancy
Needs research.

### Timestamp Manipulation
Similarly to front-running attacks, timestamp manipulation is not possible to prevent with assertions, since it's up to the block builder to decide which timestamp to use. But with the security incentives in place with the Credible Layer, the block builders / assertion enforcers would be slashed if they don't act as expected.

### Insecure Arithmetic
A very small problem these days and since solidity 0.8.0 underflow and overflows revert by default.

### Denial of Service
This kind of attack cannot be prevented by assertions. However this type of attack is much less likely to happen with dynamic gas limits from 1559.
Potentially with a cheatcode that allows the Credible Layer to check the gas limit before the transaction is sent this could somehow be prevented, but it's really not a common attack these days.

### Ether Force Feeding
Need to find a good recent example of this.

### ABI Hash Collisions
Currently it is not possible to write assertions that can prevent ABI hash collisions since this in most cases will involve checking input parameters to function calls.
With an added cheatcode that allows the Credible Layer to fetch the input parameters of a function call it might be possible to write assertions for this.
An example of how this could look is in the [RoyaltyRegistryAssertions.sol](./assertion/RoyaltyRegistryAssertions.sol) file.

### Compiler Bugs
Needs research. It might be that the Vyper compiler bug hack could have been prevented with assertions.

### Phishing
This is more of a meta attack type and hopefully combinations of above attack types can be used to prevent this.
