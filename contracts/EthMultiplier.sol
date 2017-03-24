pragma solidity ^0.4.8;

contract EthMultiplierFactory {
    
    address public owner;

    uint16 private id;
    
    uint public costToDeploy = 5 ether;
    
    struct Parameters {
        address EthMultiplier;
        uint8 feePercentage;
        uint8 payoutPercentage;
        uint maximumInvestment;
    }
    mapping (uint => Parameters) public parameters;
    
    function EthMultiplierFactory() {
        owner = msg.sender;
       // deploy(10, 25, 10 ether);
    }
    
    function deploy(
        uint8 feePercentage,
        uint8 payoutPercentage,
        uint maximumInvestment
    ) {
        parameters[id].feePercentage = feePercentage;
        parameters[id].payoutPercentage = payoutPercentage;
        parameters[id].maximumInvestment = maximumInvestment;
        parameters[id].EthMultiplier = new EthMultiplier();
        id++;
    }
    
    function getFeePercentage() external returns (uint8) {
        return parameters[id].feePercentage;
    }
    
    function getPayoutPercentage() external returns (uint8) {
        return parameters[id].payoutPercentage;
    }
    
    function getMaximumInvestment() external returns (uint) {
        return parameters[id].maximumInvestment;
    }
    
}

contract EthMultiplier {

//*****************************           **************************************
//***************************** VARIABLES **************************************
//*****************************           **************************************

//******************************************************************************
//***** PRIVATE VARS ***********************************************************
//******************************************************************************

    uint16 private id;
    uint16 private payout_id;


//******************************************************************************
//***** ENTITIES ***************************************************************
//******************************************************************************
    
//***** INVESTMENT *************************************************************
    
    struct Investment {
        address addr;
        uint remainingPayout;
        uint time;
    }
    mapping (uint16 => Investment) public investment;

    function getAddress(uint16 id) returns(address) {
        return investment[id].addr;
    }

    function getRemainingPayout(uint16 id) returns(uint) {
        return investment[id].remainingPayout;
    }

    function getIsPaidOut(uint16 id) returns(bool) {
        return investment[id].remainingPayout == 0;
    }


//******************************************************************************
//***** CALCULATE REQUIRED INVESTMENT FOR PAYOUT BY ID FUNCTION ****************
//******************************************************************************

    event manualCheckInvestmentRequiredById(uint16 investmentId, uint investmentRequired);
    
    function eventCheckInvestmentRequiredByAddress(uint16 investmentId) {
        manualCheckInvestmentRequiredById(investmentId, checkInvestmentRequiredById(investmentId));
    }

    modifier awaitingPayoutId(uint16 _investmentId) {
        if (_investmentId > id || _investmentId < payout_id) throw;
        _;
    }

    function checkInvestmentRequiredById(uint16 _investmentId)
    awaitingPayoutId(_investmentId) 
    returns(uint) {
        if (this.balance > 0) payout(true);
        uint amount;
        uint16 i = payout_id;
        while(i <= _investmentId) {
            amount += investment[i++].remainingPayout;
        }
        
        return amount * 100 / (100 - feePercentage);
    }


//***** SMART CONTRACT *********************************************************

    EthMultiplierFactory public factory;
    address public owner;
    uint8 public feePercentage;
    uint8 public payoutPercentage;
    uint public maximumInvestment;

    function getOwner() returns(address) {
        return owner;
    }
    
    function getMaximumInvestment() returns(uint) {
        return maximumInvestment;
    }

    function getFeePercentage() returns(uint8) {
        return feePercentage;
    }

    function getPayoutPercentage() returns(uint8) {
        return payoutPercentage;
    }

    function getBalance() returns(uint) {
        return this.balance;
    }
    
    
//***** TOTALS *****************************************************************

    function getTotalRemainingPayout() returns(uint total) {
        if (id == 0) return 0;
        uint16 i = id - 1;
        uint16 ii = payout_id;
        while(i >= ii) {
            total += investment[i--].remainingPayout;
        }
    }
    
    function getTotalInvested() returns(uint) {
        return getTotalRemainingPayout() * 100 / payoutPercentage;
    }

    function getTotalPaidOut() returns(uint total) {
        return getTotalInvested() * (100 - feePercentage) / 100;
    }
    
    function getTotalInvestments() returns(uint) {
        return id == 0 ? 0 : id - 1;
    }
    
    function getTotalInvestmentsAwaitingPayout() returns(uint) {
        return id - payout_id;
    }
    
    function getTotalInvestmentsPaidOut() returns(uint16 count) {
        return (payout_id == 0) ? 0 : payout_id - 1;
    }
    
    
//***** END CONTRACT ***********************************************************

    function deployNewEthMultiplier(
        uint8 feePercentage,
        uint8 payoutPercentage,
        uint maximumInvestment
    ) {
        factory.deploy(
            feePercentage,
            payoutPercentage,
            maximumInvestment
        );
    }


//*****************************           **************************************
//***************************** FUNCTIONS **************************************
//*****************************           **************************************

//******************************************************************************
//***** INIT FUNCTION **********************************************************
//******************************************************************************

    function EthMultiplier() {
        factory = EthMultiplierFactory(msg.sender);
        owner = tx.origin;
        
        feePercentage = factory.getFeePercentage();
        payoutPercentage = factory.getPayoutPercentage();
        maximumInvestment = factory.getMaximumInvestment();
    }


//******************************************************************************
//***** FALLBACK FUNCTION ******************************************************
//******************************************************************************

    function() payable {
        invest();
        if (msg.gas > 100000) payout(true);
    }


//******************************************************************************
//***** ADD INVESTMENT FUNCTION ************************************************
//******************************************************************************

// Warning! the creator of this smart contract is in no way liable
// for any losses or gains in both the 'invest' function nor 
// the 'buySmartContract' function.

// Always correctly identify the risk related before investing in this smart contract.

    function invest() payable {
        uint val = msg.value;
        
        // check investment
        if (val < 1 finney) {
            if (!msg.sender.send(val)) throw;
            return;
        }
        if (val > maximumInvestment) {
            if (!msg.sender.send(val - maximumInvestment)) throw;
            val = maximumInvestment;
        }
        
        // pay fee
        if (!owner.send(val * feePercentage / 100)) throw;
        
        // save investment
        investment[id].addr = msg.sender;
        investment[id].remainingPayout = val * (100 + payoutPercentage) / 100;
        investment[id].time = now;
    }


//******************************************************************************
//***** PAYOUT FUNCTION ********************************************************
//******************************************************************************

    event totalRemainingPayout(uint total);
    
    function payout(bool includeEvent_totalRemainingPayout) {
        uint balance = this.balance;
        uint remaining;
        
        while (balance >= investment[payout_id].remainingPayout) {
            remaining = investment[payout_id].remainingPayout;
            delete investment[payout_id].remainingPayout;
            if (!investment[payout_id++].addr.send(remaining)) throw;
            balance -= remaining;
        }
        
        investment[payout_id].remainingPayout -= balance;
        if (!investment[payout_id].addr.send(balance)) throw;
        
        if (includeEvent_totalRemainingPayout && msg.gas > 50000) 
            totalRemainingPayout(getTotalRemainingPayout());
        
    }


//******************************************************************************
//***** CHANGE OWNER FUNCTION **************************************************
//******************************************************************************

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
    

}
