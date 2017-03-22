var EthMultiplier = artifacts.require("./EthMultiplier.sol");

contract('EthMultiplier', function(accounts) {
    it("should save a player has invested", function() {

        var account_one = accounts[0];

        return EthMultiplier.deployed().then(function(instance) {
            return instance.call(1000000000000000000, {from: account_one})
        }).then(function() {
            
        })
    })
});