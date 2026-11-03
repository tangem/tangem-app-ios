//
//  YieldTransactionFee.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import BigInt

public protocol YieldTransactionFee {
    var totalFeeAmount: Amount { get }
    var maxFeePerGas: BigUInt? { get }
    var transactionFees: [Fee] { get }
}

struct DeployEnterFee: YieldTransactionFee {
    let deployFee: Fee
    let approveFee: Fee
    let enterFee: Fee?

    init(fees: [Fee]) throws {
        guard fees.count >= 2 else {
            throw YieldModuleError.feeNotFound
        }

        deployFee = fees[0]
        approveFee = fees[1]
        enterFee = fees[safe: 2]
    }

    var totalFeeAmount: Amount {
        if let enterFee {
            deployFee.amount + approveFee.amount + enterFee.amount
        } else {
            deployFee.amount + approveFee.amount
        }
    }

    var transactionFees: [Fee] {
        [deployFee, approveFee, enterFee].compactMap { $0 }
    }

    var maxFeePerGas: BigUInt? {
        (deployFee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
    }
}

struct InitEnterFee: YieldTransactionFee {
    let initFee: Fee
    let approveFee: Fee
    let enterFee: Fee?
    let newImplementationAddress: String?

    init(fees: [Fee], newImplementationAddress: String?) throws {
        guard fees.count >= 2 else {
            throw YieldModuleError.feeNotFound
        }

        initFee = fees[0]
        approveFee = fees[1]
        enterFee = fees[safe: 2]
        self.newImplementationAddress = newImplementationAddress
    }

    var totalFeeAmount: Amount {
        if let enterFee {
            initFee.amount + approveFee.amount + enterFee.amount
        } else {
            initFee.amount + approveFee.amount
        }
    }

    var transactionFees: [Fee] {
        [initFee, approveFee, enterFee].compactMap { $0 }
    }

    var maxFeePerGas: BigUInt? {
        (initFee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
    }
}

struct ReactivateEnterFee: YieldTransactionFee {
    let reactivateFee: Fee
    let approveFee: Fee?
    let enterFee: Fee?
    let newImplementationAddress: String?

    init(fees: [Fee], isEnterAvailable: Bool, isPermissionRequired: Bool, newImplementationAddress: String?) throws {
        self.newImplementationAddress = newImplementationAddress

        switch fees.count {
        case 3:
            reactivateFee = fees[0]
            approveFee = fees[1]
            enterFee = fees[2]
        case 2 where isPermissionRequired && !isEnterAvailable:
            reactivateFee = fees[0]
            approveFee = fees[1]
            enterFee = nil
        case 2 where isEnterAvailable && !isPermissionRequired:
            reactivateFee = fees[0]
            approveFee = nil
            enterFee = fees[1]
        case 1 where !isEnterAvailable && !isPermissionRequired:
            reactivateFee = fees[0]
            approveFee = nil
            enterFee = nil
        default:
            throw YieldModuleError.feeNotFound
        }
    }

    var totalFeeAmount: Amount {
        switch (approveFee, enterFee) {
        case (.some(let approveFee), .some(let enterFee)):
            approveFee.amount + enterFee.amount + reactivateFee.amount
        case (.some(let approveFee), _):
            approveFee.amount + reactivateFee.amount
        case (_, .some(let enterFee)):
            enterFee.amount + reactivateFee.amount
        default:
            reactivateFee.amount
        }
    }

    var transactionFees: [Fee] {
        [reactivateFee, approveFee, enterFee].compactMap { $0 }
    }

    var maxFeePerGas: BigUInt? {
        (reactivateFee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
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

    var transactionFees: [Fee] {
        [fee]
    }

    var maxFeePerGas: BigUInt? {
        (fee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
    }
}

struct ClaimFee: YieldTransactionFee {
    let fee: Fee
    let newImplementationAddress: String?

    init(fees: [Fee], newImplementationAddress: String?) throws {
        guard fees.count == 1 else {
            throw YieldModuleError.feeNotFound
        }

        fee = fees[0]
        self.newImplementationAddress = newImplementationAddress
    }

    var totalFeeAmount: Amount {
        fee.amount
    }

    var transactionFees: [Fee] {
        [fee]
    }

    var maxFeePerGas: BigUInt? {
        (fee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
    }
}

struct ApproveFee: YieldTransactionFee {
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

    var transactionFees: [Fee] {
        [fee]
    }

    var maxFeePerGas: BigUInt? {
        (fee.parameters as? EthereumFeeParameters)?.maximumFeePerGas
    }
}
