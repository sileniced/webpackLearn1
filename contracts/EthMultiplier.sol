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

//***** INVESTOR **************************************************************
    
    struct Investor {
        uint invested;
        uint paidOut;
        uint16 lastInvestmentId;
    }
    mapping (address => Investor) public investor;

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
    uint8 public feePercentage = 10;
    uint8 public payoutPercentage = 25;
    bool public isSmartContractForSale = true;
    uint public smartContractPrice = 25 ether;

    function getOwner() returns(address) {
        return owner;
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
    
    function getFee(uint value) returns(uint) {
        return value * feePercentage / 100;
    }
    
    function getPayout(uint value) returns(uint) {
        return value * (100 + payoutPercentage) / 100;
    }
    
    function addFees(uint value) returns(uint) {
        return value * 100 / (100 - feePercentage);
    }


//*****************************           **************************************
//***************************** FUNCTIONS **************************************
//*****************************           **************************************

//******************************************************************************
//***** CHECK REQUIRED INVESTMENT FOR PAYOUT BY ID FUNCTION ********************
//******************************************************************************

    event investmentRequiredById(uint investmentId, uint investmentRequired);

    modifier awaitingPayoutId(uint16 _investmentId) {
        if (_investmentId > id || _investmentId < payoutIdx) throw;
        _;
    }

    function checkInvestmentRequiredById(uint16 _investmentId)
    awaitingPayoutId(_investmentId) {
        uint amount;
        for (uint16 i = payoutIdx; i <= _investmentId; i++) {
            amount += investment[i].remainingPayout;
        }
        
        investmentRequiredById(_investmentId, addFees(amount));
    }


//******************************************************************************
//***** CHECK REQUIRED INVESTMENT FOR PAYOUT BY ADDRESS FUNCTION ***************
//******************************************************************************

    event investmentRequiredByAddress(address investor, uint investmentRequired);

    modifier awaitingPayoutAddress(address _investor) {
        if (getIsPaidOut(_investor)) throw;
        _;
    }

    function checkInvestmentRequiredById(address _investor)
    awaitingPayoutAddress(_investor) {
        uint amount;
        for (uint16 i = payoutIdx; i <= investor[_investor].lastInvestmentId; i++) {
            amount += investment[i].remainingPayout;
        }
        
        investmentRequiredByAddress(_investor, addFees(amount));
    }
    

//******************************************************************************
//***** INIT FUNCTION **********************************************************
//******************************************************************************

    function EthMultiplier() { 
        owner = msg.sender; 
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

    event newInvestor(
        uint16 investmentId,
        address investor,
        uint investment,
        uint investmentNeededForPayout,
        uint totalRemainingPayout,
        uint investorIdCurrentlyBeingPaidOut
    );

    modifier entryCosts(uint min, uint max) {
        if (msg.value < min || msg.value > max) throw;
        _;
    }

    function invest()
    payable
    entryCosts(1 finney, 10 ether) {
        uint payoutThisRound;
        
        investment[id].addr = msg.sender;
        investment[id].remainingPayout = getPayout(msg.value);
        investor[msg.sender].invested += msg.value;
        investor[msg.sender].lastInvestmentId = id;
        totalInvested += msg.value;
        
        owner.transfer(getFee(msg.value));
        
        do {
            if (investment[payoutIdx].remainingPayout >= this.balance) {
                investment[payoutIdx].remainingPayout -= this.balance;
                investor[investment[payoutIdx].addr].paidOut += this.balance;
                totalPaidOut += payoutThisRound + this.balance;
                investment[payoutIdx].addr.transfer(this.balance);
                if (investment[payoutIdx].remainingPayout == 0) payoutIdx++;
            } else {
                uint payout = investment[payoutIdx].remainingPayout;
                investment[payoutIdx].remainingPayout = 0;
                investor[investment[payoutIdx].addr].paidOut += payout;
                payoutThisRound += payout;
                investment[payoutIdx++].addr.transfer(payout);
            }
        } while (this.balance > 0);
        
        newInvestor(
            id++,
            msg.sender,
            msg.value,
            getTotalRemainingPayout(),
            getRemainingPayout(msg.sender),
            payoutIdx
        );
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

    function buySmartContract()
    payable
    isForSale {
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
//***** SET FEE PERCENTAGE FUNCTION ********************************************
//******************************************************************************

// the fees cannot be higher than 25%

    event newFeePercentageIsSet(uint percentage);

    modifier FPLimits(uint8 _percentage) {
        if (_percentage > 25) throw;
        _;
    }

    function setFeePercentage(uint8 _percentage)
    onlyOwner
    FPLimits(_percentage) {
        feePercentage = _percentage;
        newFeePercentageIsSet(_percentage);
    }


//******************************************************************************
//***** SET PAY OUT PERCENTAGE FUNCTION ****************************************
//******************************************************************************

// payout cannot be higher than 100% (== double the investment)
// it also cannot be lower than the fee percentage

    event newPayOutPercentageIsSet(uint percentageOnTopOfDeposit);

    modifier POTODLimits(uint8 _percentage) {
        if (_percentage > 100 || _percentage < feePercentage) throw;
        _;
    }

    function setPayOutPercentage(uint8 _percentageOnTopOfDeposit)
    onlyOwner
    POTODLimits(_percentageOnTopOfDeposit) {
        payoutPercentage = _percentageOnTopOfDeposit;
        newPayOutPercentageIsSet(_percentageOnTopOfDeposit);
    }


//******************************************************************************
//***** SET SMART CONTRACT SALE FUNCTION ***************************************
//******************************************************************************

    event smartContractSaleStarted(uint price);
    event smartContractSaleEnded();

    function putSmartContractOnSale(bool _sell)
    onlyOwner {
        isSmartContractForSale = _sell;
        _sell? 
        smartContractSaleStarted(smartContractPrice): 
        smartContractSaleEnded();
    }


//******************************************************************************
//***** SET SMART CONTRACT PRICE FUNCTION **************************************
//******************************************************************************

// smart contract price cannot be lower or equal than 10 ether

    event smartContractPriceIsSet(uint price);

    modifier SCPLimits(uint _price) {
        if (_price <= 10 ether) throw;
        _;
    }

    function setSmartContractPrice(uint _price)
    onlyOwner 
    SCPLimits(_price) {
        smartContractPrice = _price;
        smartContractPriceIsSet(_price);
    }


}