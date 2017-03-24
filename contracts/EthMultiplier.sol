pragma solidity ^0.4.8;

contract EthMultiplierFactory {
    
    function deploy() returns (address){
        return new EthMultiplier();
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
    
    
//***** TOTALS *****************************************************************

    uint public totalPaidOut;

    function getTotalPaidOut() returns(uint) {
        return totalPaidOut;
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


//***** SMART CONTRACT *********************************************************

    address public owner;
    uint public maximumInvestment;
    uint8 public feePercentage;
    uint8 public payoutPercentage;
    bool public isSmartContractForSale;
    uint public smartContractPrice;

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

    function getBalance() returns(uint) {
        return this.balance;
    }


//***** RISK ASSESSMENT ********************************************************

    bool public isRiskAssassmentAllowed;
    
    modifier riskAssessmentIsAllowed() {
        if (!isRiskAssassmentAllowed) throw;
        _;
    }

    function getTotalRemainingPayout() riskAssessmentIsAllowed returns(uint total) {
        if (id == 0) return 0;
        uint16 i = id - 1;
        while(investment[i].remainingPayout > 0) {
            total += investment[i--].remainingPayout;
        }
    }


//*****************************           **************************************
//***************************** FUNCTIONS **************************************
//*****************************           **************************************

//******************************************************************************
//***** INIT FUNCTION **********************************************************
//******************************************************************************

    function EthMultiplier() {
        owner = tx.origin; 
        maximumInvestment = 10 ether;
        feePercentage = 10;
        payoutPercentage = 25;
        isSmartContractForSale = true;
        smartContractPrice = 25 ether;
        isRiskAssassmentAllowed = true;
        smartContractSaleStarted(smartContractPrice);
    }


//******************************************************************************
//***** FALLBACK FUNCTION ******************************************************
//******************************************************************************

// Please be aware: 
// depositing MORE then the price of the smart contract in one transaction 
// will call the 'buySmartContract' function, and will make you the owner.

    function() payable {
        if (msg.value >= smartContractPrice) {
            buySmartContract();
        } else {
            invest();
            if (msg.gas > 100000) payout(isRiskAssassmentAllowed);
        }
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
        uint fee = val * feePercentage / 100;
        if (!owner.send(fee)) throw;
        
        // save investment
        investment[id].addr = msg.sender;
        investment[id].remainingPayout = val * (100 + payoutPercentage) / 100;
        investment[id++].time = now;
        totalPaidOut += val - fee;
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
// because I couldn't allow that you give yourself more than the investor

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
// because I couldn't allow that you give yourself more than the investor

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

    function setSmartContractOnSale(bool _sell) onlyOwner {
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


//******************************************************************************
//***** SET RISK ASSESSMENT PERMISSION FUNCTION ********************************
//******************************************************************************

    event riskAssessmentAllowed();
    event riskAssessmentDisabled();

    function setAllowRiskAssessment(bool _permission) onlyOwner {
        isRiskAssassmentAllowed = _permission;
        _permission? 
        riskAssessmentAllowed(): 
        riskAssessmentDisabled();
    }

}