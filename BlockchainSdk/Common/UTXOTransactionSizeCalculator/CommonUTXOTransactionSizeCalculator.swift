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

    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) -> Int {
        let inputsSize = inputs.sum(by: \.script.type.inputSize)
        let outputsSize = outputs.sum(by: \.outputSize)
        let isWitness = inputs.contains(where: { $0.script.type.isWitness }) || outputs.contains { $0.isWitness }
        let headerSize = isWitness ? Constants.witnessTransactionHeaderSize : Constants.transactionHeaderSize
        return headerSize + inputsSize + outputsSize
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
         - Version: 4 bytes
         - Marker: 1 byte (0x00)
         - Flag: 1 byte (0x01)
         - Input count (var_int): 1-9 bytes (typically 1 byte)
         - Output count (var_int): 1-9 bytes (typically 1 byte)
         - Locktime: 4 bytes
          */
        static let witnessTransactionHeaderSize = 12
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
            // signature (71-73 bytes) + script bytes (DER encoding + sighash) ≈ 114 bytes
            return 114
        case .p2pkh:
            // signature (71-73 bytes) + pubkey (33 bytes) + script overhead ≈ 148 bytes
            return 148
        case .p2sh:
            // Typical multisig redeem script + signatures + script overhead ≈ 297 bytes
            return 297
        case .p2wpkh:
            // Segregated witness format: signature + pubkey in witness data ≈ 69 bytes
            return 69
        case .p2wsh:
            // Witness program hash (32 bytes) + script version (1 byte) + overhead ≈ 41 bytes
            return 41
        case .p2tr:
            // P2TR: 1 byte version + 32 bytes key + 33 bytes signature
            return 66
        }
    }

    var outputSize: Int {
        switch self {
        case .p2pk:
            // Public key (33 bytes) + OP_CHECKSIG + script overhead = 44 bytes
            return 44
        case .p2pkh:
            // OP_DUP + OP_HASH160 + push(20) + pubKeyHash(20) + OP_EQUALVERIFY + OP_CHECKSIG = 25 bytes
            return 25
        case .p2sh:
            // OP_HASH160 + push(20) + scriptHash(20) + OP_EQUAL = 23 bytes
            return 23
        case .p2wpkh:
            // Version(1) + push(20) + witness program(20) + script overhead = 22 bytes
            return 22
        case .p2wsh:
            // Version(1) + push(32) + witness program(32) + script overhead = 43 bytes
            return 43
        case .p2tr:
            // P2TR: 1 byte version + 32 bytes key
            return 34
        }
    }
}
