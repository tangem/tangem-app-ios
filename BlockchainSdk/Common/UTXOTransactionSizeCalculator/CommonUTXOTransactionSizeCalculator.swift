//
//  CommonUTXOTransactionSizeCalculator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonUTXOTransactionSizeCalculator: UTXOTransactionSizeCalculator {
    private let network: UTXONetworkParams

    init(network: UTXONetworkParams) {
        self.network = network
    }

    /// Calculates the dust threshold for this script type
    /// Based on Bitcoin Core's GetDustThreshold implementation
    /// https://github.com/bitcoin/bitcoin/blob/dfb7d58108daf3728f69292b9e6dba437bb79cc7/src/policy/policy.cpp#L26
    /// - Parameter dustRelayFee: Fee rate in satoshis per kilobyte
    /// - Returns: Dust threshold in satoshis
    func dust(type: UTXOScriptType) -> Int {
        let threshold = outputSize(scriptType: type) * network.dustRelayTxFee / 1000

        if type.isWitness {
            return max(threshold, 294)
        }

        return max(threshold, 546)
    }

    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) throws -> Int {
        let headerSize = Constants.transactionHeaderSize
        let inputsSize = try inputs.reduce(0) { try $0 + inputSize(script: $1.script) }
        let outputsSize = outputs.reduce(0) { $0 + outputSize(scriptType: $1) }

        let baseData = headerSize + inputsSize + outputsSize

        var witnessData = 0
        if inputs.contains(where: { $0.script.type.isWitness }) || outputs.contains(where: { $0.isWitness }) {
            try inputs.forEach {
                witnessData += try witnessDataSize(script: $0.script)
            }

            witnessData += Constants.witnessHeaderMarkerSize
        }

        let weight = baseData * 4 + witnessData
        let bytes = toBytes(vBytes: weight)
        return bytes
    }

    private func inputSize(script: UTXOLockingScript) throws -> Int {
        switch (script.type, script.spendable) {
        // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + signature(72) + pushByte(1) + sequence(4)
        case (.p2pk, .some): 114

        // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + signature(72) + pushByte(1) + PubKey(33) + pushByte(1) + sequence(4)
        case (.p2pkh, .publicKey(let publicKey)): 115 + publicKey.count

        // OP_0(1) + RedeemScript(71) + sigLength(1) + signature(72)
        // Applicable for Twin Cards
        case (.p2sh, .redeemScript(let redeemScript)): 75 + redeemScript.count

        // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + sequence(4)
        case (.p2wpkh, .some), (.p2wsh, .some), (.p2tr, .some): 41

        // Error cases
        case (_, .none), (.p2sh, .publicKey), (.p2pkh, .redeemScript):
            throw UTXOTransactionSizeCalculatorError.unableToSpend
        }
    }

    private func witnessDataSize(script: UTXOLockingScript) throws -> Int {
        switch (script.type, script.spendable) {
        // Non witness input
        case (.p2pk, .some), (.p2pkh, .some), (.p2sh, .some):
            return 0

        // StackItem(1) + sigLength(1) + signature(72) + pushByte(1) + PubKey(33)
        case (.p2wpkh, .publicKey(let data)), (.p2wsh, .redeemScript(let data)), (.p2tr, .publicKey(let data)):
            return 1 + 73 + OpCode.push(data).count

        // Error cases
        case (_, .none), (.p2wsh, .publicKey), (.p2wpkh, .redeemScript), (.p2tr, .redeemScript):
            throw UTXOTransactionSizeCalculatorError.unableToSpend
        }
    }

    private func outputSize(scriptType: UTXOScriptType) -> Int {
        let lockingScriptSize = switch scriptType {
        // keyLength(1) + PublicKey (33 bytes) + OP_CHECKSIG(1)
        case .p2pk: 35

        // OP_DUP(1) + OP_HASH160(1) + pushKeyHash(1 + 20) + OP_EQUALVERIFY(1) + OP_CHECKSIG(1)
        case .p2pkh: 25

        // OP_HASH160(1) + pushKeyHash(1 + 20) + OP_EQUAL(1)
        case .p2sh: 23

        // Version(1) + pushKeyHash(1 + 20)
        case .p2wpkh: 22

        // Version(1) + pushKeyHash(1 + 32)
        case .p2wsh, .p2tr: 34
        }

        // SpentValue(8) + scriptLength(1) + LockingScriptSize
        return 8 + 1 + lockingScriptSize
    }

    private func toBytes(vBytes: Int) -> Int {
        vBytes / 4 + (vBytes % 4 == 0 ? 0 : 1)
    }
}

extension CommonUTXOTransactionSizeCalculator {
    enum Constants {
        /**
         Basic transaction header components:
         - Version: 4 bytes
         - Input count (var_int): 1-9 bytes (typically 1 byte)
         - Output count (var_int): 1-9 bytes (typically 1 byte)
         - Locktime: 4 bytes
         */
        static let transactionHeaderSize = 10

        /**
         Witness transaction header components:
         - Marker: 1 byte (0x00)
         - Flag: 1 byte (0x01)
          */
        static let witnessHeaderMarkerSize = 2
    }
}

// MARK: - UTXOScriptType+

extension UTXOScriptType {
    var isWitness: Bool {
        switch self {
        case .p2wsh, .p2wpkh, .p2tr: true
        case .p2pk, .p2pkh, .p2sh: false
        }
    }
}
