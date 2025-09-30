//
//  YieldTransactionFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol YieldTransactionFee {
    var totalFeeAmount: Amount { get }
}

struct DeployEnterFee: YieldTransactionFee {
    let deployFee: Fee
    let approveFee: Fee
    let enterFee: Fee

    var totalFeeAmount: Amount {
        deployFee.amount + approveFee.amount + enterFee.amount
    }
}

struct InitEnterFee: YieldTransactionFee {
    let initFee: Fee
    let enterFee: EnterFee

    var totalFeeAmount: Amount {
        initFee.amount + enterFee.totalFeeAmount
    }
}

struct ReactivateEnterFee: YieldTransactionFee {
    let reactivateFee: Fee
    let enterFee: EnterFee

    var totalFeeAmount: Amount {
        reactivateFee.amount + enterFee.totalFeeAmount
    }
}

struct EnterFee: YieldTransactionFee {
    let enterFee: Fee
    let approveFee: Fee?

    var totalFeeAmount: Amount {
        if let approveFee {
            enterFee.amount + approveFee.amount
        } else {
            enterFee.amount
        }
    }
}

struct ExitFee: YieldTransactionFee {
    let fee: Fee

    var totalFeeAmount: Amount {
        fee.amount
    }
}
