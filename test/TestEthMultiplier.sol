pragma solidity ^0.4.8;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EthMultiplier.sol";

contract TestEthMultiplier {

    function testInitialOwnerSettings() {
        EthMultiplier mult = EthMultiplier(DeployedAddresses.EthMultiplier());

        address expected = ;

        Assert.equal(mult.getOwner(), expected, "Deployer is not the owner");
    }


    function testFallBackFromFirstInvestor {
        EthMultiplier mult = EthMultiplier(DeployedAddresses.EthMultiplier());

        uint expected = 
    }
}