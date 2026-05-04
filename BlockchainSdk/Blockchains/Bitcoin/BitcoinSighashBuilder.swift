//
//  BitcoinSighash.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Shared sighash builder for Bitcoin-style transactions (legacy + segwit v0).
/// Extracted from `CommonUTXOTransactionSerializer` so app-level features (e.g. WalletConnect PSBT)
/// can reuse the exact same preimage rules without duplicating Bitcoin encoding logic.
enum BitcoinSighashBuilder {
    struct Input: Sendable, Hashable {
        /// 32 bytes as provided by upstream decoder (BDK/WalletCore). Must be used consistently.
        public let txid: Data
        public let vout: UInt32
        public let sequence: UInt32

        public init(txid: Data, vout: UInt32, sequence: UInt32) {
            self.txid = txid
            self.vout = vout
            self.sequence = sequence
        }
    }

    struct Output: Sendable, Hashable {
        public let value: UInt64
        public let scriptPubKey: Data

        public init(value: UInt64, scriptPubKey: Data) {
            self.value = value
            self.scriptPubKey = scriptPubKey
        }
    }

    /// Legacy (pre-segwit) sighash for a single input.
    /// - Note: `sighashType` is the 4-byte value appended to the preimage (little-endian), e.g. 1 for BTC SIGHASH_ALL, 0x41 for BCH ALL|FORKID.
    static func legacySighash(
        version: UInt32,
        lockTime: UInt32,
        inputs: [Input],
        outputs: [Output],
        inputIndex: Int,
        scriptCode: Data,
        sighashType: UInt32
    ) throws -> Data {
        guard inputs.indices.contains(inputIndex) else {
            throw Error.inputIndexOutOfRange
        }

        var bytes = Data()
        bytes += version.littleEndianData

        bytes += VariantIntEncoder.encode(UInt64(inputs.count))
        for (idx, input) in inputs.enumerated() {
            bytes += input.txid
            bytes += input.vout.littleEndianData

            if idx == inputIndex {
                bytes += VariantIntEncoder.encode(UInt64(scriptCode.count))
                bytes += scriptCode
            } else {
                bytes += Data([0x00])
            }

            bytes += input.sequence.littleEndianData
        }

        bytes += VariantIntEncoder.encode(UInt64(outputs.count))
        for output in outputs {
            bytes += output.value.littleEndianData
            bytes += VariantIntEncoder.encode(UInt64(output.scriptPubKey.count))
            bytes += output.scriptPubKey
        }

        bytes += lockTime.littleEndianData
        bytes += sighashType.littleEndianData

        return bytes.getDoubleSHA256()
    }

    /// Convenience wrapper for BTC-style SIGHASH_ALL (1).
    static func legacySighashAll(
        version: UInt32,
        lockTime: UInt32,
        inputs: [Input],
        outputs: [Output],
        inputIndex: Int,
        scriptCode: Data
    ) throws -> Data {
        try legacySighash(
            version: version,
            lockTime: lockTime,
            inputs: inputs,
            outputs: outputs,
            inputIndex: inputIndex,
            scriptCode: scriptCode,
            sighashType: 1
        )
    }

    /// SegWit v0 (BIP143) sighash for a single input.
    /// - Note: `sighashType` is the 4-byte value appended to the preimage (little-endian).
    static func segwitV0Sighash(
        version: UInt32,
        lockTime: UInt32,
        inputs: [Input],
        outputs: [Output],
        inputIndex: Int,
        scriptCode: Data,
        value: UInt64,
        sighashType: UInt32
    ) throws -> Data {
        guard inputs.indices.contains(inputIndex) else {
            throw Error.inputIndexOutOfRange
        }

        var bytes = Data()
        bytes += version.littleEndianData

        let prevouts = inputs.flatMap { input in
            input.txid + input.vout.littleEndianData
        }
        bytes += Data(prevouts).getDoubleSHA256()

        let sequences = inputs.flatMap { input in
            input.sequence.littleEndianData
        }
        bytes += Data(sequences).getDoubleSHA256()

        let input = inputs[inputIndex]
        bytes += input.txid
        bytes += input.vout.littleEndianData

        bytes += VariantIntEncoder.encode(UInt64(scriptCode.count))
        bytes += scriptCode

        bytes += value.littleEndianData
        bytes += input.sequence.littleEndianData

        let outs = outputs.flatMap { output in
            output.value.littleEndianData + VariantIntEncoder.encode(UInt64(output.scriptPubKey.count)) + output.scriptPubKey
        }
        bytes += Data(outs).getDoubleSHA256()

        bytes += lockTime.littleEndianData
        bytes += sighashType.littleEndianData

        return bytes.getDoubleSHA256()
    }

    /// Convenience wrapper for BTC-style SIGHASH_ALL (1).
    static func segwitV0SighashAll(
        version: UInt32,
        lockTime: UInt32,
        inputs: [Input],
        outputs: [Output],
        inputIndex: Int,
        scriptCode: Data,
        value: UInt64
    ) throws -> Data {
        try segwitV0Sighash(
            version: version,
            lockTime: lockTime,
            inputs: inputs,
            outputs: outputs,
            inputIndex: inputIndex,
            scriptCode: scriptCode,
            value: value,
            sighashType: 1
        )
    }
}

extension BitcoinSighashBuilder {
    enum Error: Swift.Error {
        case inputIndexOutOfRange
    }
}

// MARK: - Helpers

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var v = littleEndian
        return withUnsafeBytes(of: &v) { Data($0) }
    }
}
