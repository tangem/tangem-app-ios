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
    var totalFee: Fee { get }
}

struct DeployEnterFee: YieldTransactionFee {
    let deployFee: Fee
    let enterFee: EnterFee

    init(deployFee: Fee) {
        self.deployFee = deployFee
        enterFee = .defaultFee(fee: deployFee)
    }

    var totalFee: Fee {
        let value = deployFee.amount.value + enterFee.totalFee.amount.value
        return Fee(Amount(with: deployFee.amount, value: value), parameters: deployFee.parameters)
    }
}

struct InitEnterFee: YieldTransactionFee {
    let initFee: Fee
    let enterFee: EnterFee

    init(initFee: Fee) {
        self.initFee = initFee
        enterFee = .defaultFee(fee: initFee)
    }

    var totalFee: Fee {
        let value = initFee.amount.value + enterFee.totalFee.amount.value
        return Fee(Amount(with: initFee.amount, value: value), parameters: initFee.parameters)
    }
}

struct ReactivateEnterFee: YieldTransactionFee {
    let reactivateFee: Fee
    let enterFee: EnterFee

    var totalFee: Fee {
        let value = reactivateFee.amount.value + enterFee.totalFee.amount.value
        return Fee(Amount(with: reactivateFee.amount, value: value), parameters: reactivateFee.parameters)
    }
}

struct EnterFee: YieldTransactionFee {
    let enterFee: Fee
    let approveFee: Fee?

    var totalFee: Fee {
        let value = enterFee.amount.value + (approveFee?.amount.value ?? .zero)

        return Fee(Amount(with: enterFee.amount, value: value), parameters: enterFee.parameters)
    }

    static func defaultFee(approveFee: Fee) -> EnterFee {
        EnterFee(
            enterFee: Fee(
                Amount(with: approveFee.amount, value: YieldConstants.maxNetworkFee), parameters: approveFee.parameters
            ),
            approveFee: approveFee
        )
    }

    static func defaultFee(fee: Fee) -> EnterFee {
        EnterFee(
            enterFee: Fee(
                Amount(with: fee.amount, value: YieldConstants.maxNetworkFee), parameters: fee.parameters
            ),
            approveFee: Fee(
                Amount(with: fee.amount, value: YieldConstants.maxNetworkFee), parameters: fee.parameters
            )
        )
    }
}
