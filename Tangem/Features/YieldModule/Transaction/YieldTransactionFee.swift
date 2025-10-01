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
    init(fees: [Fee]) throws

    var totalFeeAmount: Amount { get }
}

struct DeployEnterFee: YieldTransactionFee {
    let deployFee: Fee
    let approveFee: Fee
    let enterFee: Fee

    init(fees: [Fee]) throws {
        guard fees.count == 3 else {
            throw YieldModuleError.feeNotFound
        }

        deployFee = fees[0]
        approveFee = fees[1]
        enterFee = fees[2]
    }

    var totalFeeAmount: Amount {
        deployFee.amount + approveFee.amount + enterFee.amount
    }
}

struct InitEnterFee: YieldTransactionFee {
    let initFee: Fee
    let enterFee: EnterFee

    init(fees: [Fee]) throws {
        guard fees.count == 3 else { // on enter approve is mandatory
            throw YieldModuleError.feeNotFound
        }

        initFee = fees[0]
        let approveFee = fees[1]
        let enterFee = fees[2]

        self.enterFee = EnterFee(enterFee: enterFee, approveFee: approveFee)
    }

    var totalFeeAmount: Amount {
        initFee.amount + enterFee.totalFeeAmount
    }
}

struct ReactivateEnterFee: YieldTransactionFee {
    let reactivateFee: Fee
    let enterFee: EnterFee

    init(fees: [Fee]) throws {
        reactivateFee = fees[0]

        let approveFee: Fee?
        let enterFee: Fee

        switch fees.count {
        case 2: // without approve
            approveFee = nil
            enterFee = fees[1]
        case 3: // with approve
            approveFee = fees[1]
            enterFee = fees[2]
        default:
            throw YieldModuleError.feeNotFound
        }

        self.enterFee = EnterFee(enterFee: enterFee, approveFee: approveFee)
    }

    var totalFeeAmount: Amount {
        reactivateFee.amount + enterFee.totalFeeAmount
    }
}

struct EnterFee {
    let enterFee: Fee
    let approveFee: Fee?
}

extension EnterFee: YieldTransactionFee {
    init(fees: [Fee]) throws {
        switch fees.count {
        case 1:
            enterFee = fees[0]
            approveFee = nil
        case 2:
            approveFee = fees[0]
            enterFee = fees[1]
        default:
            throw YieldModuleError.feeNotFound
        }
    }

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

    init(fees: [Fee]) throws {
        guard fees.count == 1 else {
            throw YieldModuleError.feeNotFound
        }

        fee = fees[0]
    }

    var totalFeeAmount: Amount {
        fee.amount
    }
}
