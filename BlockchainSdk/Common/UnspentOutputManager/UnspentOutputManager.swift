//
//  UnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: String) throws
    func update(outputs: [UnspentOutput], for script: UTXOLockingScript)

    func preImage(amount: Int, fee: Int, destination: String) throws -> PreImageTransaction
    func preImage(amount: Int, feeRate: Int, destination: String) throws -> PreImageTransaction

    /// Outputs which possible to spent
    func availableOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64
}

extension UnspentOutputManager {
    func update(outputs: [UnspentOutput], for address: any Address) {
        switch address {
        case let address as LockingScriptAddress:
            update(outputs: outputs, for: address.lockingScript)
        case let address:
            do {
                BSDKLogger.warning("Update outputs with plain address. Better to use LockingScriptAddress in your address service")
                try update(outputs: outputs, for: address.value)
            } catch {
                BSDKLogger.error("Update outputs error", error: error)
            }
        }
    }

    func preImage(transaction: Transaction) throws -> PreImageTransaction {
        assert(!transaction.fee.amount.isZero, "Use preImage(amount:, feeRate:, destination:) for calculating fee")

        let amount = transaction.amount.asSmallest().value.intValue()
        let fee = transaction.fee.amount.asSmallest().value.intValue()
        return try preImage(amount: amount, fee: fee, destination: transaction.destinationAddress)
    }

    func balance(blockchain: Blockchain) -> Decimal {
        let balance = confirmedBalance() + unconfirmedBalance()
        return Decimal(balance) / blockchain.decimalValue
    }
}

struct PreImageTransaction: Hashable {
    let inputs: [ScriptUnspentOutput]
    let outputs: [OutputType]
    let fee: Int
}

extension PreImageTransaction {
    enum OutputType: Hashable {
        case destination(UTXOLockingScript, value: Int)
        case change(UTXOLockingScript, value: Int)

        var isDestination: Bool {
            switch self {
            case .destination: true
            case .change: false
            }
        }

        var isChange: Bool {
            switch self {
            case .destination: false
            case .change: true
            }
        }

        var script: UTXOLockingScript {
            switch self {
            case .destination(let script, _): script
            case .change(let script, _): script
            }
        }

        var value: Int {
            switch self {
            case .destination(_, let value): value
            case .change(_, let value): value
            }
        }
    }
}
