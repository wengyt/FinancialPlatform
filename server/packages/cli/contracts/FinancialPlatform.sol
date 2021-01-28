pragma solidity ^0.4.22;
//pragma solidity ^0.4.22;
 
/* @title 基于供应链的金融平台 */
contract FinancialPlatform {
    /* 这里声明了一个新的复合类型用于稍后的变量 */

    /*应收款单据,用于凭证、转账、融资 */
    struct Receipt {
        
        /*不可更新 */
        /*单据ID，用于查询等 */
        uint    recpID; 
        /*发起者地址 */         
        address fromAdr;
        /*收款人地址 */           
        address toAdr;
        /*金额 */             
        uint    recpAmount;
        /*确认人地址，0代表没有确认人 */
        address confirmer;     
        
        /*可被更新 */
        /*是否已融资 */
        bool    financed;  
        /*是否已结算（由核心公司） */     
        bool    settled;           
        /*被转让记录，里面是用此receipt作为凭证的转账的recpID */
        uint[]  transRecord;  
        /*剩余价值，实际可用于转账、融资、还款得到的剩余价值 */
        uint    residualValue;         
        
    }
    
    /*机构 */
    struct Agency {
    	/*机构地址 */
        address agenAdr;   
        /*机构类型 0为核心企业 1为银行 2为中小企业 */         
        uint    agenRole;              
    }

    /*写入单据，第一个参数 new表示新的receipt，fresh表示刷新的receipt */
    event LatestReceipt(string ReceiptType, uint recpID, address fromAdr, address toAdr, uint recpAmount, address confirmer, bool financed, bool settled, uint[] transRecord, uint residualValue);
    mapping(address => Agency) public agencies;
    Agency [] public agenciesInChain;
    Receipt[] public receipts;



    /*功能一：实现 签发应收账款-交易上链 */
    /*由核心企业发起，receiver为收款方，confirmer为见证的金融机构，amount为金额 */
    /*首先核心机构、见证方和收款方入链，之后单据入链并打印 */
    function AddContract(address receiver, address confirmer, uint amount) {
        /*核心机构入链 */
        agenciesInChain.push(Agency(msg.sender, 0));
        agencies[msg.sender] = agenciesInChain[0];
        /*见证方（这里是银行）入链 */
        agenciesInChain.push(Agency(confirmer, 1));
        agencies[confirmer] = agenciesInChain[1];
        /*收款方入链 */
        agenciesInChain.push(Agency(receiver, 2));
        agencies[receiver] = agenciesInChain[2];
        
        /*单据入链 */
        receipts.length ++;
        receipts[receipts.length - 1].recpID        = receipts.length;
        receipts[receipts.length - 1].fromAdr       = msg.sender;
        receipts[receipts.length - 1].toAdr         = receiver;
        receipts[receipts.length - 1].recpAmount    = amount;
        receipts[receipts.length - 1].financed      = false;
        receipts[receipts.length - 1].settled       = false;
        receipts[receipts.length - 1].confirmer     = confirmer;
        receipts[receipts.length - 1].residualValue = amount;
        /*单据打印 */
        emit LatestReceipt("new", receipts[receipts.length - 1].recpID, receipts[receipts.length - 1].fromAdr, receipts[receipts.length - 1].toAdr, receipts[receipts.length - 1].recpAmount, receipts[receipts.length - 1].confirmer, receipts[receipts.length - 1].financed, receipts[receipts.length - 1].settled, receipts[receipts.length - 1].transRecord, receipts[receipts.length - 1].residualValue);

    }

    /*检查agency 是否在链上 */
    function InChain(address tempAdr) public view returns (bool) {
        bool isInChain = false;
        for (uint i = 0; i < agenciesInChain.length; i ++) {
            if (agenciesInChain[i].agenAdr == tempAdr) {
                isInChain = true;
                break;
            }
        }
        return isInChain;
    }

    /*授权入链，只有已经在链上的才能给别人授权2 */
    function giveRightToIn(address tempAdr) public {
        require(
            InChain(msg.sender),
            "Only Agency already in this chain can give right to get in this chain."
        );
        if (!InChain(tempAdr)) {
            agenciesInChain.push(Agency(tempAdr, 2));
            agencies[tempAdr] = agenciesInChain[agenciesInChain.length - 1];
        }
    }


    /*功能二：实现应收账款的转让上链 */
    /*由票据拥有者发起，receiver为收款方，amout为金额，receiptID为所用的转让单据ID */
    /*首先检查合法性，收款方入链，之后新单据入链并打印、旧单据更新并打印 */
    function Transfer(address receiver, uint amount, uint recpID) {
        /*由票据拥有者发起 */
        require(
            msg.sender == receipts[recpID].toAdr,
            "Only receipt owner can give right to transfer."
        );
        /*没有被用来融资 */
        require(
            !receipts[recpID].financed,
            "This receipt has been used to financing."
        );
        /*金额足够 */
        require(
            receipts[recpID].residualValue >= amount,
            "This receipt's residualValue is not enough now."
        );

        /*收款方入链(若还没有在链上) */
        giveRightToIn(receiver);

        /*新单据入链并打印 */
        receipts.length ++;
        receipts[receipts.length - 1].recpID        = receipts.length;
        receipts[receipts.length - 1].fromAdr       = msg.sender;
        receipts[receipts.length - 1].toAdr         = receiver;
        receipts[receipts.length - 1].recpAmount    = amount;
        receipts[receipts.length - 1].financed      = false;
        receipts[receipts.length - 1].settled       = false;
        receipts[receipts.length - 1].residualValue = amount;
        emit LatestReceipt("new", receipts[receipts.length - 1].recpID, receipts[receipts.length - 1].fromAdr, receipts[receipts.length - 1].toAdr, receipts[receipts.length - 1].recpAmount, receipts[receipts.length - 1].confirmer, receipts[receipts.length - 1].financed, receipts[receipts.length - 1].settled, receipts[receipts.length - 1].transRecord, receipts[receipts.length - 1].residualValue);

        /*旧单据更新并打印 */
        receipts[recpID].transRecord.push(receipts.length - 1);
        receipts[recpID].residualValue -= amount;
        emit LatestReceipt("fresh", receipts[recpID].recpID, receipts[recpID].fromAdr, receipts[recpID].toAdr, receipts[recpID].recpAmount, receipts[recpID].confirmer, receipts[recpID].financed, receipts[recpID].settled, receipts[recpID].transRecord, receipts[recpID].residualValue);
    }

    /*功能三： 利用应收账款向银行融资上链 */
    /*由票据拥有者发起，recpID为所用的转让单据ID */
    /*首先检查合法性，之后旧单据更新并打印 */
    function Financing(uint recpID) {
        /*由票据拥有者发起 */
        require(
            msg.sender == receipts[recpID].toAdr,
            "Only receipt owner can give right to transfer."
        );
        /*没有被用来融资 */
        require(
            !receipts[recpID].financed,
            "This receipt has been used to financing."
        );
        receipts[recpID].financed = true;
        emit LatestReceipt("fresh", receipts[recpID].recpID, receipts[recpID].fromAdr, receipts[recpID].toAdr, receipts[recpID].recpAmount, receipts[recpID].confirmer, receipts[recpID].financed, receipts[recpID].settled, receipts[recpID].transRecord, receipts[recpID].residualValue);
    }

    /*功能四：应收账款支付结算上链 */
    /*由中小企业设置，recpID为所用的单据ID，一个receipt只能找核心企业结算其leftValue值 */
    function Settle(uint recpID) {
        /*由票据拥有者发起 */
        require(
            msg.sender == receipts[recpID].toAdr,
            "Only receipt owner can give right to transfer."
        );
        receipts[recpID].settled = true;
        emit LatestReceipt("fresh", receipts[recpID].recpID, receipts[recpID].fromAdr, receipts[recpID].toAdr, receipts[recpID].recpAmount, receipts[recpID].confirmer, receipts[recpID].financed, receipts[recpID].settled, receipts[recpID].transRecord, receipts[recpID].residualValue);
    }

    /*功能五 查询和打印单据 */
    /*所有人均可发起 */
    function printRecipt(uint recpID) public view {
        emit LatestReceipt("fresh", receipts[recpID].recpID, receipts[recpID].fromAdr, receipts[recpID].toAdr, receipts[recpID].recpAmount, receipts[recpID].confirmer, receipts[recpID].financed, receipts[recpID].settled, receipts[recpID].transRecord, receipts[recpID].residualValue);
    }

    /*功能六 第三方对单据认证 */
    /*由第三方发起，receiptID为验证的单据ID */
    /*首先检查合法性，之后旧单据更新并打印 */
    function Prove(uint recpID) {
        /*由第三方发起 */
        require(
            msg.sender == agenciesInChain[1].agenAdr,
            "Only bank can give right to prove this receipt."
        );
        receipts[recpID].confirmer = msg.sender;
        emit LatestReceipt("fresh", receipts[recpID].recpID, receipts[recpID].fromAdr, receipts[recpID].toAdr, receipts[recpID].recpAmount, receipts[recpID].confirmer, receipts[recpID].financed, receipts[recpID].settled, receipts[recpID].transRecord, receipts[recpID].residualValue);
    }
}

