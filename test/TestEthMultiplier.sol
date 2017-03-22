pragma solidity ^0.4.10;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EthMultiplier.sol";

contract TestEthMultiplier {

    function testInitialOwnerSettings() {
        EthMultiplier mult = EthMultiplier(DeployedAddresses.EthMultiplier());

        uint expected = tx.origin;

        Assert.equal(mult.getOwner(), expected, "Deployer is not the owner");
    }

}