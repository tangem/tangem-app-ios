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

    func preImage(amount: Int, fee: Int, destination: String, changeAddress: String, opReturn: Data?) async throws -> PreImageTransaction
    func preImage(amount: Int, feeRate: Int, destination: String, changeAddress: String, opReturn: Data?) async throws -> PreImageTransaction

    /// Outputs which possible to spent
    func availableOutputs() -> [ScriptUnspentOutput]

    func confirmedBalance() -> UInt64
    func unconfirmedBalance() -> UInt64

    /// Clear cached outputs
    func clearOutputs()
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

    func preImage(transaction: Transaction) async throws -> PreImageTransaction {
        assert(!transaction.fee.amount.isZero, "Use preImage(amount:, feeRate:, destination:, changeAddress:) for calculating fee")

        let amount = transaction.amount.asSmallest().value.intValue()
        let fee = transaction.fee.amount.asSmallest().value.intValue()
        let opReturn = try opReturn(from: transaction)
        let preImage = try await preImage(amount: amount, fee: fee, destination: transaction.destinationAddress, changeAddress: transaction.changeAddress, opReturn: opReturn)
        return preImage
    }

    func balance(blockchain: Blockchain) -> Decimal {
        let balance = confirmedBalance() + unconfirmedBalance()
        return Decimal(balance) / blockchain.decimalValue
    }
}

private extension UnspentOutputManager {
    func opReturn(from transaction: Transaction) throws -> Data? {
        guard let params = transaction.params as? BitcoinTransactionParams else {
            return nil
        }

        guard !params.memo.isEmpty else {
            return nil
        }

        // Standard OP_RETURN relay policy historically limits data to 80 bytes.
        if params.memo.count > UnspentOutputManagerConstants.opReturnMaxDataSizeBytes {
            throw UTXOTransactionSerializerError.walletCoreError("UTXO memo exceeds 80 bytes")
        }

        return params.memo
    }
}

struct PreImageTransaction: Hashable {
    let inputs: [ScriptUnspentOutput]
    let outputs: [OutputType]
    let fee: Int
    let opReturn: Data?
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
