//
//  KaspaUTXOTransactionSizeCalculator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaUTXOTransactionSizeCalculator: UTXOTransactionSizeCalculator {
    private let network: UTXONetworkParams

    init(network: UTXONetworkParams) {
        self.network = network
    }

    /// Dust
    /// https://kaspa-mdbook.aspectron.com/transactions/constraints/dust.html
    func dust(type: UTXOScriptType) -> Int {
        let threshold = outputSize(scriptType: type) * network.dustRelayTxFee / 1000
        return max(threshold, 546)
    }

    /// Mass
    /// https://kaspa-mdbook.aspectron.com/transactions/constraints/mass.html
    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) throws -> Int {
        let size = try size(inputs: inputs, outputs: outputs)

        let txMass = size * Constants.massPerTxByte

        // outputs scripts size
        let scriptsMass = outputs.reduce(0) { result, output in
            let scriptSize = 2 + output.lockingScriptSize // version + script size
            let scriptMass = scriptSize * Constants.massPerScriptPubKeyByte
            return result + scriptMass
        }

        // Because SigOps is equal 1. We change take count
        let sigOpsMass = inputs.count * Constants.massPerSigOp

        let mass = txMass + scriptsMass + sigOpsMass
        return mass
    }

    /// https://kaspa-mdbook.aspectron.com/transactions/constraints/size.html
    private func size(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) throws -> Int {
        var size = 0
        size += 2 // version (UInt16)
        size += 8 // number of inputs (UInt64)
        size += try inputs.reduce(0) { try $0 + inputSize(script: $1.script) }
        size += 8 // number of outputs (UInt64)
        size += outputs.reduce(0) { $0 + outputSize(scriptType: $1) }
        size += 8 // lockTime (UInt64)
        size += 20 // subnetwork ID (20 bytes)
        size += 8 // gas (UInt64)
        size += 32 // payload hash (32 bytes)
        size += 8 // payload length (UInt64)
        size += 0 // payload count (0) in our case
        return size
    }

    private func inputSize(script: UTXOLockingScript) throws -> Int {
        // Kaspa supports only this type
        guard script.type == .p2pk else {
            throw UTXOTransactionSizeCalculatorError.unableToSpend
        }

        var size = 0
        size += 32 // Previous transaction ID
        size += 4 // Index (UInt32)
        size += 8 // length of signature script (UInt64)
        size += 66 // signatureScript
        size += 8 // sequence (UInt64)
        return size
    }

    private func outputSize(scriptType: UTXOScriptType) -> Int {
        var size = 0
        size += 8 // value (UInt64)
        size += 2 // version (UInt16)
        size += 8 // length of script public key (UInt64)
        size += scriptType.lockingScriptSize // script public key
        return size
    }
}

extension KaspaUTXOTransactionSizeCalculator {
    enum Constants {
        static let massPerTxByte: Int = 1
        static let massPerScriptPubKeyByte: Int = 10
        static let massPerSigOp: Int = 1000
    }
}
