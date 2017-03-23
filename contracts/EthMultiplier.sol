pragma solidity ^0.4.10;

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

//***** INVESTOR ***************************************************************
    
    struct Investor {
        uint invested;
        uint paidOut;
        uint16 lastInvestmentId;
    }
    mapping (address => Investor) public investor;
    
    function getInvestorBalance(address addr) returns(uint) {
        return addr.balance;
    }

    function getInvested(address addr) returns(uint) {
        return investor[addr].invested;
    }

    function getPaidOut(address addr) returns(uint) {
        return investor[addr].paidOut;
    }
    
    function getLastInvestmentId(address addr) returns(uint16) {
        return investor[addr].lastInvestmentId;
    }

    function getPromised(address addr) returns(uint) {
        return investor[addr].invested * (100 + payoutPercentage) / 100;
    }

    function getRemainingPayout(address addr) returns(uint) {
        return getPromised(addr) - investor[addr].paidOut;
    }

    function getIsPaidOut(address addr) returns(bool) {
        return getPromised(addr) == investor[addr].paidOut;
    }

    function getProfit(address addr) returns(uint) {
        if (investor[addr].invested > investor[addr].paidOut) return 0;
        return investor[addr].paidOut - investor[addr].invested;
    }


//******************************************************************************
//***** CALCULATE REQUIRED INVESTMENT FOR PAYOUT BY ADDRESS FUNCTION ***********
//******************************************************************************

    event manualCheckInvestmentRequiredByAddress(address investor, uint investmentRequired);
    
    function eventCheckInvestmentRequiredByAddress(address investor) {
        manualCheckInvestmentRequiredByAddress(investor, checkInvestmentRequiredByAddress(investor));
    }

    modifier awaitingPayoutAddress(address _investor) {
        if (getIsPaidOut(_investor)) throw;
        _;
    }

    function checkInvestmentRequiredByAddress(address _investor)
    awaitingPayoutAddress(_investor)
    returns(uint) {
        if (this.balance > 0) payout();
        uint amount;
        uint16 lastInvestment = investor[_investor].lastInvestmentId;
        for (uint16 i = payoutIdx; i <= lastInvestment; i++) {
            amount += investment[i].remainingPayout;
        }
        
        return addFees(amount);
    }
    
    
//***** INVESTMENT *************************************************************
    
    struct Investment {
        address addr;
        uint investment;
        uint remainingPayout;
    }
    mapping (uint16 => Investment) public investment;

    function getAddressById(uint16 id) returns(address) {
        return investment[id].addr;
    }

    function getRemainingPayoutById(uint16 id) returns(uint) {
        return investment[id].remainingPayout;
    }

    function getInvestmentById(uint16 id) returns(uint) {
        return investment[id].investment;
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

    uint public totalInvested;
    uint public totalPaidOut;

    function getTotalInvested() returns(uint) {
        return totalInvested;
    }

    function getTotalPaidOut() returns(uint) {
        return totalPaidOut;
    }

    function getTotalPromised() returns(uint) {
        return totalInvested * (100 + payoutPercentage) / 100;
    }

    function getTotalRemainingPayout() returns(uint) {
        return getTotalPromised() - totalPaidOut;
    }


//***** SMART CONTRACT *********************************************************

    address public owner;
    uint public maximumInvestment = 10 ether;
    uint8 public feePercentage = 10;
    uint8 public payoutPercentage = 25;
    bool public isSmartContractForSale = true;
    uint public smartContractPrice = 25 ether;
    
    function getBalance() returns(uint) {
        return this.balance;
    }
    
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
            msg.sender.transfer(investmentValue);
            return 0;
        }
        
        if (investmentValue > maximumInvestment) {
            msg.sender.transfer(maximumInvestment - investmentValue);
            investmentValue = maximumInvestment;
        }
        
        // send fees
        owner.transfer(calculateFee(investmentValue));
        
        return investmentValue;
    }
    
    
    function save(uint investmentValue) private returns(bool) {
        if (investmentValue == 0) return false;
        
        // save investor
        investor[msg.sender].invested += investmentValue;
        investor[msg.sender].lastInvestmentId = id++;
        
        // save investment
        investment[id].addr = msg.sender;
        investment[id].remainingPayout = calculatePayout(investmentValue);
        
        // add to totals
        totalInvested += investmentValue;
        
        return true;
    }
    
    
    function payout() {
        uint balance = this.balance;
        uint payoutRound;
        uint remaining;
        address payoutTo;
        
        while (balance > 0) {
            payoutTo = investment[payoutIdx].addr;
            remaining = investment[payoutIdx].remainingPayout;
            if (remaining > balance) {
                investment[payoutIdx].remainingPayout -= balance;
                investor[payoutTo].paidOut += balance;
                totalPaidOut += payoutRound + balance;
                payoutTo.transfer(balance);
                return;
            } else {
                delete investment[payoutIdx++].remainingPayout;
                investor[payoutTo].paidOut += remaining;
                payoutTo.transfer(remaining);
                if (balance == remaining) {
                    totalPaidOut += payoutRound + remaining;
                    return;
                } else {
                    payoutRound += remaining;
                    balance -= remaining;
                }
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
            msg.sender.transfer(msg.value - smartContractPrice);
    }

    function buySmartContract() payable isForSale {
        owner.transfer(smartContractPrice);
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

    event newFeePercentageIsSet(uint8 percentage);

    modifier FPLimits(uint8 _percentage) {
        if (_percentage > 25) throw;
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