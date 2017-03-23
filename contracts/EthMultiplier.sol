pragma solidity ^0.4.8;

contract EthMultiplier {

//*****************************           **************************************
//***************************** VARIABLES **************************************
//*****************************           **************************************

//******************************************************************************
//***** PRIVATE VARS ***********************************************************
//******************************************************************************

    uint16 private id;
    uint16 private payoutIdx;


//******************************************************************************
//***** ENTITIES ***************************************************************
//******************************************************************************
    
//***** INVESTMENT *************************************************************
    
    struct Investment {
        address addr;
        uint remainingPayout;
    }
    mapping (uint16 => Investment) public investment;

    function getAddressById(uint16 id) returns(address) {
        return investment[id].addr;
    }

    function getRemainingPayoutById(uint16 id) returns(uint) {
        return investment[id].remainingPayout;
    }

    function getIsPaidOutById(uint16 id) returns(bool) {
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
        if (_investmentId > id || _investmentId < payoutIdx) throw;
        _;
    }

    function checkInvestmentRequiredById(uint16 _investmentId)
    awaitingPayoutId(_investmentId) 
    returns(uint) {
        if (this.balance > 0) payout();
        uint amount;
        for (uint16 i = payoutIdx; i <= _investmentId; i++) {
            amount += investment[i].remainingPayout;
        }
        
        return addFees(amount);
    }
    
    
//***** TOTALS *****************************************************************

    uint public totalPaidOut;

    function getTotalPaidOut() returns(uint) {
        return totalPaidOut;
    }
    
    function getTotalInvestments() returns(uint16) {
        return (id == 0) ? 0 : id - 1;
    }
    
    function getTotalInvestmentsAwaitingPayout() returns(uint16) {
        return id - payoutIdx;
    }
    
    function getTotalInvestmentsPaidOut() returns(uint16 count) {
        return (id == 0 || payoutIdx == 0) ? 0 : payoutIdx - 1;
    }

    function getTotalRemainingPayout() returns(uint total) {
        if (id == 0 || payoutIdx == 0) return 0;
        for (uint16 i = id - 1; investment[i].remainingPayout > 0; i--) {
            total += investment[i].remainingPayout;
        }
    }


//***** SMART CONTRACT *********************************************************

    address public owner;
    uint public maximumInvestment = 10 ether;
    uint8 public feePercentage = 10;
    uint8 public payoutPercentage = 25;
    bool public isSmartContractForSale = true;
    uint public smartContractPrice = 25 ether;

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

    function getIsSmartContractForSale() returns(bool) {
        return isSmartContractForSale;
    }

    function getSmartContractPrice() returns(uint) {
        return smartContractPrice;
    }
    
    function calculateFee(uint value) private returns(uint) {
        return value * feePercentage / 100;
    }
    
    function addFees(uint value) private returns(uint) {
        return value * 100 / (100 - feePercentage);
    }
    
    function calculatePayout(uint value) private returns(uint) {
        return value * (100 + payoutPercentage) / 100;
    }

    function getBalance() returns(uint) {
        return this.balance;
    }


//*****************************           **************************************
//***************************** FUNCTIONS **************************************
//*****************************           **************************************

//******************************************************************************
//***** INIT FUNCTION **********************************************************
//******************************************************************************

    function EthMultiplier() {
        owner = tx.origin; 
        smartContractSaleStarted(smartContractPrice);
    }


//******************************************************************************
//***** FALLBACK FUNCTION ******************************************************
//******************************************************************************

// Please be aware: 
// depositing MORE then the price of the smart contract in one transaction 
// will call the 'buySmartContract' function, and will make you the owner.

    function()
    payable {
        msg.value >= smartContractPrice? 
        buySmartContract(): 
        invest();
    }


//******************************************************************************
//***** ADD INVESTMENT FUNCTION ************************************************
//******************************************************************************

// Warning! the creator of this smart contract is in no way liable
// for any losses or gains in both the 'invest' function nor 
// the 'buySmartContract' function.

// Always correctly identify the risk related before investing in this smart contract.

    function invest() payable {
        if (save(check(msg.value)) && msg.gas > 100000) payout();
    }
    
    
    function check(uint investmentValue) private returns(uint) {
        if (investmentValue < 1 finney) {
            if (!msg.sender.send(investmentValue)) throw;
            return 0;
        }
        
        if (investmentValue > maximumInvestment) {
            if (!msg.sender.send(maximumInvestment - investmentValue)) throw;
            investmentValue = maximumInvestment;
        }
        
        // send fees
        uint fee = calculateFee(investmentValue);
        if (!owner.send(fee)) throw;
        totalPaidOut += investmentValue - fee;
        
        return investmentValue;
    }
    
    
    function save(uint investmentValue) private returns(bool) {
        if (investmentValue == 0) return false;
        
        // save investment
        investment[id].addr = msg.sender;
        investment[id].remainingPayout = calculatePayout(investmentValue);
        
        return true;
    }
    
    
    function payout() {
        uint balance = this.balance;
        uint remaining;
        address payoutTo;
        
        while (balance > 0) {
            payoutTo = investment[payoutIdx].addr;
            remaining = investment[payoutIdx].remainingPayout;
            if (balance < remaining) {
                investment[payoutIdx].remainingPayout -= balance;
                if (!payoutTo.send(balance)) throw;
                return;
            } else {
                delete investment[payoutIdx++].remainingPayout;
                if (!payoutTo.send(remaining)) throw;
                balance -= remaining;
            }
        }
    }


//******************************************************************************
//***** BUY SMART CONTRACT FUNCTION ********************************************
//******************************************************************************

// Warning! the creator of this smart contract is in no way liable
// for any losses or gains in both the 'invest' function nor 
// the 'buySmartContract' function.

// Always correctly identify the risk related before buying this smart contract.

    event newOwner(uint pricePayed);

    modifier isForSale() {
        if (!isSmartContractForSale 
        || msg.value < smartContractPrice 
        || msg.sender == owner) throw;
        _;
        if (msg.value > smartContractPrice)
            if (!msg.sender.send(msg.value - smartContractPrice)) throw;
    }

    function buySmartContract() payable isForSale {
        if (!owner.send(smartContractPrice)) throw;
        owner = msg.sender;
        isSmartContractForSale = false;
        newOwner(smartContractPrice);
    }


//********************                               ***************************
//******************** SETTER FUNCTIONS (OWNER ONLY) ***************************
//********************                               ***************************

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }


//******************************************************************************
//***** CHANGE OWNER FUNCTION **************************************************
//******************************************************************************

    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }


//******************************************************************************
//***** SET MAXIMUM INVESTMENT FUNCTION ****************************************
//******************************************************************************

// the maximum investment cannot be lower than 1 ether and
// it cannot be higher that the price of the smart contract

    event newMaximumInvestmentIsSet(uint maximumInvestment);

    modifier MILimits(uint _maximum) {
        if (_maximum < 1 ether || _maximum >= smartContractPrice) throw;
        _;
    }

    function setFeePercentage(uint _maximum) onlyOwner
    MILimits(_maximum) {
        maximumInvestment = _maximum;
        newMaximumInvestmentIsSet(_maximum);
    }


//******************************************************************************
//***** SET FEE PERCENTAGE FUNCTION ********************************************
//******************************************************************************

// the fees cannot be higher than 25%
// it also cannot be higher than the payout percentage
// because I won't allow that you give yourself more than the investor

    event newFeePercentageIsSet(uint8 percentage);

    modifier FPLimits(uint8 _percentage) {
        if (_percentage > 25 || _percentage > payoutPercentage) throw;
        _;
    }

    function setFeePercentage(uint8 _percentage) onlyOwner
    FPLimits(_percentage) {
        feePercentage = _percentage;
        newFeePercentageIsSet(_percentage);
    }


//******************************************************************************
//***** SET PAY OUT PERCENTAGE FUNCTION ****************************************
//******************************************************************************

// payout cannot be higher than 200% (== triple the investment)
// it also cannot be lower than the fee percentage
// because I won't allow that you give yourself more than the investor

    event newPayOutPercentageIsSet(uint percentageOnTopOfDeposit);

    modifier POTODLimits(uint8 _percentage) {
        if (_percentage > 200 || _percentage < feePercentage) throw;
        _;
    }

    function setPayOutPercentage(uint8 _percentageOnTopOfDeposit) onlyOwner
    POTODLimits(_percentageOnTopOfDeposit) {
        payoutPercentage = _percentageOnTopOfDeposit;
        newPayOutPercentageIsSet(_percentageOnTopOfDeposit);
    }


//******************************************************************************
//***** SET SMART CONTRACT SALE FUNCTION ***************************************
//******************************************************************************

    event smartContractSaleStarted(uint price);
    event smartContractSaleEnded();

    function putSmartContractOnSale(bool _sell) onlyOwner {
        isSmartContractForSale = _sell;
        _sell? 
        smartContractSaleStarted(smartContractPrice): 
        smartContractSaleEnded();
    }


//******************************************************************************
//***** SET SMART CONTRACT PRICE FUNCTION **************************************
//******************************************************************************

// smart contract price cannot be lower or equal than the maximum investment
// because that would create a conflict in the fallback function

    event smartContractPriceIsSet(uint price);

    modifier SCPLimits(uint _price) {
        if (_price <= maximumInvestment) throw;
        _;
    }

    function setSmartContractPrice(uint _price) onlyOwner 
    SCPLimits(_price) {
        smartContractPrice = _price;
        smartContractPriceIsSet(_price);
    }


}