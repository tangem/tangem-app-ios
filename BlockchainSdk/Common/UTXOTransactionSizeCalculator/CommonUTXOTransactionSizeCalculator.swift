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
        let threshold = type.outputSize * network.dustRelayTxFee / 1000

        if type.isWitness {
            return max(threshold, 294)
        }

        return max(threshold, 546)
    }

    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) throws -> Int {
        let headerSize = Constants.transactionHeaderSize
        let inputsSize = inputs.sum(by: \.script.type.inputSize)
        let outputsSize = outputs.sum(by: \.outputSize)

        let baseData = headerSize + inputsSize + outputsSize

        var witnessData = 0
        if inputs.contains(where: { $0.script.type.isWitness }) || outputs.contains(where: { $0.isWitness }) {
            inputs.forEach { _ in
                witnessData += Constants.witnessData
            }
            witnessData += Constants.witnessHeaderMarkerSize
        }

        let weight = baseData * 4 + witnessData
        let bytes = toBytes(vBytes: weight)
        return bytes
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

        /// StackItem(1) + pushSignature(73) + pushPubKey(33)
        /// [REDACTED_TODO_COMMENT]
        /// Because `108` size is not possible
        static let witnessData = 108
    }
}

// MARK: - UTXOScriptType+

extension UTXOScriptType {
    var isWitness: Bool {
        self == .p2wsh || self == .p2wpkh || self == .p2tr
    }

    var inputSize: Int {
        switch self {
        case .p2pk:
            // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + signature(72) + pushByte(1) + sequence(4)
            return 114
        case .p2pkh:
            // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + signature(72) + pushByte(1) + PubKey(33) + pushByte(1) + sequence(4)
            // [REDACTED_TODO_COMMENT]
            // Because decide on pub key size
            return 180
        case .p2sh:
            // Typical multisig redeem script + signatures + script overhead ≈ 297 bytes
            return 297
        case .p2wpkh, .p2wsh, .p2tr:
            // PreviousOutputHex(32) + InputIndex(4) + sigLength(1) + sequence(4)
            return 41
        }
    }

    var lockingScriptSize: Int {
        switch self {
        case .p2pk:
            // keyLength(1) + PublicKey (33 bytes) + OP_CHECKSIG(1)
            return 35
        case .p2pkh:
            // OP_DUP(1) + OP_HASH160(1) + pushKeyHash(1 + 20) + OP_EQUALVERIFY(1) + OP_CHECKSIG(1)
            return 25
        case .p2sh:
            // OP_HASH160(1) + pushKeyHash(1 + 20) + OP_EQUAL(1)
            return 23
        case .p2wpkh:
            // Version(1) + pushKeyHash(1 + 20)
            return 22
        case .p2wsh:
            // Version(1) + pushKeyHash(1 + 32)
            return 34
        case .p2tr:
            // Version(1) + pushKeyHash(1 + 32)
            return 34
        }
    }

    var outputSize: Int {
        // SpentValue(8) + scriptLength(1) + LockingScriptSize
        return 8 + 1 + lockingScriptSize
    }
}
