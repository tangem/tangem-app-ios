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

    var totalFee: Fee { get }
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

    var totalFee: Fee {
        let value = deployFee.amount.value + approveFee.amount.value + enterFee.amount.value
        return Fee(Amount(with: deployFee.amount, value: value), parameters: deployFee.parameters)
    }
}

struct InitEnterFee: YieldTransactionFee {
    let initFee: Fee
    let enterFee: EnterFee

    init(fees: [Fee]) throws {
        guard fees.count == 3 else {
            throw YieldModuleError.feeNotFound
        }

        initFee = fees[0]
        enterFee = EnterFee(enterFee: fees[1], approveFee: fees[2])
    }

    var totalFee: Fee {
        let value = initFee.amount.value + enterFee.totalFee.amount.value
        return Fee(Amount(with: initFee.amount, value: value), parameters: initFee.parameters)
    }
}

struct ReactivateEnterFee: YieldTransactionFee {
    let reactivateFee: Fee
    let enterFee: EnterFee

    init(fees: [Fee]) throws {
        guard fees.count >= 2 else {
            throw YieldModuleError.feeNotFound
        }

        reactivateFee = fees[0]
        enterFee = EnterFee(enterFee: fees[1], approveFee: fees[safe: 2])
    }

    var totalFee: Fee {
        let value = reactivateFee.amount.value + enterFee.totalFee.amount.value
        return Fee(Amount(with: reactivateFee.amount, value: value), parameters: reactivateFee.parameters)
    }
}

struct EnterFee {
    let enterFee: Fee
    let approveFee: Fee?
}

extension EnterFee: YieldTransactionFee {
    init(fees: [Fee]) throws {
        guard fees.count >= 1 else {
            throw YieldModuleError.feeNotFound
        }

        enterFee = fees[0]
        approveFee = fees[safe: 1]
    }

    var totalFee: Fee {
        let value = enterFee.amount.value + (approveFee?.amount.value ?? .zero)

        return Fee(Amount(with: enterFee.amount, value: value), parameters: enterFee.parameters)
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

    var totalFee: Fee {
        fee
    }
}

private extension Fee {
    func defaultFee() -> Fee {
        Fee(Amount(with: amount, value: YieldConstants.maxNetworkFee), parameters: parameters)
    }
}
