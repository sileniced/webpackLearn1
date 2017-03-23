var EthMultiplier = artifacts.require("./EthMultiplier.sol");

contract('EthMultiplier', function(accounts) {
    it("should make the deployer the owner", function() {

        var expectedOwner = accounts[0];

        return EthMultiplier.deployed().then(function(instance) {
            return instance.getOwner.call()
        }).then(function(owner) {
            assert.equal(owner, expectedOwner, "Deployer is not the owner");
        })
    });

    it("should give 90% back in the first fallback", function() {
        
    });
});