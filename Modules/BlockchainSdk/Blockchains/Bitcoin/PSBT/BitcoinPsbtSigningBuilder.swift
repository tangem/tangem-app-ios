//
//  BitcoinPsbtSigningBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import BitcoinDevKit
import TangemSdk

/// PSBT signing helper for BTC-style transactions (p2pkh + segwit-v0 p2wpkh).
/// Supports BTC-style SIGHASH_ALL (0x01) and Bitcoin Cash SIGHASH_ALL|FORKID (0x41, p2pkh only).
///
/// - Important: BitcoinDevKit Swift bindings do not currently expose mutable PSBT maps.
///   We therefore insert `partial_sigs` via `PsbtKeyValueMap`, then finalize the PSBT via `BitcoinDevKit.Psbt.finalize()`.
///   FORKID inputs are finalized manually instead: BDK (rust-bitcoin) rejects a `partial_sigs`
///   entry with the non-standard 0x41 sighash byte at PSBT parse time.
/// - Important: `BitcoinDevKit.Psbt.extractTx()` enforces a BTC-centric fee-rate sanity cap
///   (`AbsurdFeeRate`, ~25k sat/vB) that normal Dogecoin fees exceed, and the bindings expose
///   no uncapped variant (rust-bitcoin's `extract_tx_with_fee_rate_limit` is not wrapped by bdk-ffi).
///   It stays the primary path. Only when the caller passes `PsbtFeeRateLimit.chainOverride`
///   (defined for Dogecoin only) AND the fee rate BDK reported is within that chain's limit
///   do we fall back: transaction structure is read from the PSBT global map, and the final raw
///   transaction is extracted by BDK itself from a zero-fee copy of the PSBT
///   (see `zeroFeeExtractionCopyBase64`). A fee rate above the limit is a drain attempt
///   and rethrows `AbsurdFeeRate`.
public enum BitcoinPsbtSigningBuilder {
    /// The PSBT inputs whose spending UTXO is locked by one of the wallet's `ownerScriptPubKeys`, paired with that script.
    public static func ownedInputs(
        psbtBase64: String,
        ownerScriptPubKeys: Set<Data>,
        feeRateLimit: PsbtFeeRateLimit = .bdkDefault
    ) throws -> [(index: Int, scriptPubKey: Data)] {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let psbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try transaction(psbt: psbt, psbtData: psbtData, feeRateLimit: feeRateLimit)
        let txInputs = tx.input()
        let psbtInputs = psbt.input()

        return try txInputs.indices.compactMap { index in
            let outpoint = txInputs[index].previousOutput
            let utxo = try spendingUtxo(psbtInput: psbtInputs[index], vout: outpoint.vout)
            let scriptPubKey = utxo.scriptPubkey.toBytes()
            return ownerScriptPubKeys.contains(scriptPubKey) ? (index: index, scriptPubKey: scriptPubKey) : nil
        }
    }

    /// Extract the raw, network-ready transaction (hex) from a finalized PSBT.
    public static func extractRawTransactionHex(finalizedPsbtBase64: String, feeRateLimit: PsbtFeeRateLimit = .bdkDefault) throws -> String {
        guard let psbtData = Data(base64Encoded: finalizedPsbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        do {
            return try Psbt(psbtBase64: finalizedPsbtBase64).extractTx().serialize().hex()
        } catch let error as ExtractTxError {
            guard case .AbsurdFeeRate(let feeRate) = error,
                  case .chainOverride(let limit) = feeRateLimit,
                  feeRate <= limit else {
                throw error
            }
        }

        let psbt = try Psbt(psbtBase64: finalizedPsbtBase64)
        let extractionCopyBase64 = try zeroFeeExtractionCopyBase64(psbtData: psbtData, psbtInputs: psbt.input())
        return try Psbt(psbtBase64: extractionCopyBase64).extractTx().serialize().hex()
    }

    /// The miner fee (in satoshi) the PSBT pays: total inputs value minus total outputs value.
    public static func fee(psbtBase64: String, feeRateLimit: PsbtFeeRateLimit = .bdkDefault) throws -> UInt64 {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let psbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try transaction(psbt: psbt, psbtData: psbtData, feeRateLimit: feeRateLimit)
        let txInputs = tx.input()
        let psbtInputs = psbt.input()

        var totalIn: UInt64 = 0
        for index in txInputs.indices {
            let outpoint = txInputs[index].previousOutput
            let utxo = try spendingUtxo(psbtInput: psbtInputs[index], vout: outpoint.vout)
            totalIn = try addOrThrow(totalIn, utxo.value.toSat())
        }

        let totalOut = try tx.output().reduce(UInt64(0)) { try addOrThrow($0, $1.value.toSat()) }

        guard totalIn >= totalOut else {
            throw BlockchainSdk.BitcoinError.invalidPsbt("Inputs total is less than outputs total")
        }

        return totalIn - totalOut
    }

    /// The total value (in satoshi) the PSBT sends to outputs not owned by the wallet.
    public static func sentAmount(
        psbtBase64: String,
        ownerScriptPubKeys: Set<Data>,
        feeRateLimit: PsbtFeeRateLimit = .bdkDefault
    ) throws -> UInt64 {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let psbt = try Psbt(psbtBase64: psbtBase64)
        return try transaction(psbt: psbt, psbtData: psbtData, feeRateLimit: feeRateLimit).output()
            .filter { !ownerScriptPubKeys.contains($0.scriptPubkey.toBytes()) }
            .reduce(UInt64(0)) { try addOrThrow($0, $1.value.toSat()) }
    }

    /// Build hashes that must be signed for the given PSBT inputs (sorted by index).
    /// - Note: Returned hashes are double-SHA256 for BTC SIGHASH_ALL.
    public static func hashesToSign(psbtBase64: String, signInputs: [SignInput]) throws -> [Data] {
        try hashesToSign(psbtBase64: psbtBase64, signInputs: signInputs, signHashType: .bitcoinAll)
    }

    /// Build hashes that must be signed for the given PSBT inputs (sorted by index).
    /// - Note: Returned hashes are double-SHA256 for the given `signHashType`.
    static func hashesToSign(
        psbtBase64: String,
        signInputs: [SignInput],
        signHashType: UTXONetworkParamsSignHashType,
        feeRateLimit: PsbtFeeRateLimit = .bdkDefault
    ) throws -> [Data] {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let psbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try transaction(psbt: psbt, psbtData: psbtData, feeRateLimit: feeRateLimit)
        let txInputs = tx.input()
        let txOutputs = tx.output()
        let psbtInputs = psbt.input()

        let indices = signInputs.map(\.index).sorted()
        var hashes: [Data] = []
        hashes.reserveCapacity(indices.count)

        for index in indices {
            hashes.append(
                try sighashAll(
                    tx: tx,
                    txInputs: txInputs,
                    txOutputs: txOutputs,
                    psbtInputs: psbtInputs,
                    inputIndex: index,
                    signHashType: signHashType
                )
            )
        }

        return hashes
    }

    /// Apply signatures, finalize inputs and return a base64 PSBT.
    /// - Important: `signatures` and `publicKeys` must align with `signInputs` sorted by index (the `hashesToSign` order).
    public static func applySignaturesAndFinalize(
        psbtBase64: String,
        signInputs: [SignInput],
        signatures: [SignatureInfo],
        publicKeys: [Data]
    ) throws -> String {
        try applySignaturesAndFinalize(
            psbtBase64: psbtBase64,
            signInputs: signInputs,
            signatures: signatures,
            publicKeys: publicKeys,
            signHashType: .bitcoinAll
        )
    }

    /// Apply signatures, finalize inputs and return a base64 PSBT.
    /// - Important: `signatures` and `publicKeys` must align with `signInputs` sorted by index (the `hashesToSign` order).
    static func applySignaturesAndFinalize(
        psbtBase64: String,
        signInputs: [SignInput],
        signatures: [SignatureInfo],
        publicKeys: [Data],
        signHashType: UTXONetworkParamsSignHashType,
        feeRateLimit: PsbtFeeRateLimit = .bdkDefault
    ) throws -> String {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let bdkPsbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try transaction(psbt: bdkPsbt, psbtData: psbtData, feeRateLimit: feeRateLimit)
        let inputCount = tx.input().count
        let outputCount = tx.output().count

        var psbtMaps: PsbtKeyValueMap
        do {
            psbtMaps = try PsbtKeyValueMap(data: psbtData, inputCount: inputCount, outputCount: outputCount)
        } catch {
            throw BlockchainSdk.BitcoinError.invalidPsbt(String(describing: error))
        }

        let indices = signInputs.map(\.index).sorted()
        guard indices.count == signatures.count, indices.count == publicKeys.count else {
            throw BlockchainSdk.BitcoinError.wrongSignaturesCount
        }

        for (i, inputIndex) in indices.enumerated() {
            guard inputIndex >= 0, inputIndex < inputCount else {
                throw BlockchainSdk.BitcoinError.inputIndexOutOfRange(inputIndex)
            }

            // PSBT partial sigs / scriptSig expect DER signature + 1-byte sighash type.
            let der = try signatures[i].der()
            let sigWithHashType = der + Data([signHashType.value])

            do {
                switch signHashType {
                case .bitcoinAll:
                    try psbtMaps.setPartialSignature(
                        inputIndex: inputIndex,
                        publicKey: publicKeys[i],
                        signatureWithSighash: sigWithHashType
                    )
                case .bitcoinCashAll:
                    let finalScriptSig = OpCode.push(sigWithHashType) + OpCode.push(publicKeys[i])
                    try psbtMaps.finalizeInput(inputIndex: inputIndex, finalScriptSig: finalScriptSig)
                }
            } catch let error as BlockchainSdk.BitcoinError {
                throw BlockchainSdk.BitcoinError.invalidPsbt(error.localizedDescription)
            }
        }

        switch signHashType {
        case .bitcoinAll:
            // Let BitcoinDevKit finalize (fills finalScriptSig/finalScriptWitness when possible).
            let signedBase64 = psbtMaps.serialize().base64EncodedString()
            let bdkSigned = try Psbt(psbtBase64: signedBase64)
            let finalized = bdkSigned.finalize()

            guard finalized.couldFinalize else {
                throw BlockchainSdk.BitcoinError.invalidPsbt("Could not finalize PSBT")
            }

            return finalized.psbt.serialize()
        case .bitcoinCashAll:
            guard (0 ..< inputCount).allSatisfy({ psbtMaps.isInputFinalized(inputIndex: $0) }) else {
                throw BlockchainSdk.BitcoinError.invalidPsbt("Could not finalize PSBT")
            }

            return psbtMaps.serialize().base64EncodedString()
        }
    }

    /// Single-key convenience: stamps the same `publicKey` on every signed input.
    public static func applySignaturesAndFinalize(
        psbtBase64: String,
        signInputs: [SignInput],
        signatures: [SignatureInfo],
        publicKey: Data
    ) throws -> String {
        try applySignaturesAndFinalize(
            psbtBase64: psbtBase64,
            signInputs: signInputs,
            signatures: signatures,
            publicKeys: Array(repeating: publicKey, count: signatures.count)
        )
    }
}

// MARK: - Sighash

private extension BitcoinPsbtSigningBuilder {
    static func sighashAll(
        tx: BitcoinDevKit.Transaction,
        txInputs: [BitcoinDevKit.TxIn],
        txOutputs: [BitcoinDevKit.TxOut],
        psbtInputs: [BitcoinDevKit.Input],
        inputIndex: Int,
        signHashType: UTXONetworkParamsSignHashType
    ) throws -> Data {
        guard txInputs.indices.contains(inputIndex) else {
            throw BlockchainSdk.BitcoinError.inputIndexOutOfRange(inputIndex)
        }

        guard psbtInputs.indices.contains(inputIndex) else {
            throw BlockchainSdk.BitcoinError.inputIndexOutOfRange(inputIndex)
        }

        let outpoint = txInputs[inputIndex].previousOutput
        let utxo = try spendingUtxo(psbtInput: psbtInputs[inputIndex], vout: outpoint.vout)
        let scriptPubKey = utxo.scriptPubkey.toBytes()
        let scriptType = PsbtScriptPubKeyType(scriptPubKey: scriptPubKey)

        let sighashInputs = txInputs.map {
            BitcoinSighashBuilder.Input(
                txid: $0.previousOutput.txid.serialize(),
                vout: $0.previousOutput.vout,
                sequence: $0.sequence
            )
        }

        let sighashOutputs = txOutputs.map {
            BitcoinSighashBuilder.Output(
                value: $0.value.toSat(),
                scriptPubKey: $0.scriptPubkey.toBytes()
            )
        }

        let version = UInt32(bitPattern: tx.version())
        let lockTime = tx.lockTime()

        switch (scriptType, signHashType) {
        case (.p2pkh, .bitcoinAll):
            return try BitcoinSighashBuilder.legacySighashAll(
                version: version,
                lockTime: lockTime,
                inputs: sighashInputs,
                outputs: sighashOutputs,
                inputIndex: inputIndex,
                scriptCode: scriptPubKey
            )
        case (.p2pkh, .bitcoinCashAll):
            return try BitcoinSighashBuilder.segwitV0Sighash(
                version: version,
                lockTime: lockTime,
                inputs: sighashInputs,
                outputs: sighashOutputs,
                inputIndex: inputIndex,
                scriptCode: scriptPubKey,
                value: utxo.value.toSat(),
                sighashType: UInt32(signHashType.value)
            )
        case (.p2wpkh, .bitcoinAll):
            let pubKeyHash = scriptPubKey.subdata(in: 2 ..< 22)
            return try BitcoinSighashBuilder.segwitV0SighashAll(
                version: version,
                lockTime: lockTime,
                inputs: sighashInputs,
                outputs: sighashOutputs,
                inputIndex: inputIndex,
                scriptCode: OpCodeUtils.p2pkh(data: pubKeyHash),
                value: utxo.value.toSat()
            )
        case (.p2wpkh, .bitcoinCashAll):
            throw BlockchainSdk.BitcoinError.unsupported("SegWit inputs are not supported for FORKID sighash")
        case (.unsupported(let reason), _):
            throw BlockchainSdk.BitcoinError.unsupported(reason)
        }
    }

    static func transaction(psbt: Psbt, psbtData: Data, feeRateLimit: PsbtFeeRateLimit) throws -> BitcoinDevKit.Transaction {
        do {
            return try psbt.extractTx()
        } catch let error as ExtractTxError {
            guard case .AbsurdFeeRate(let feeRate) = error,
                  case .chainOverride(let limit) = feeRateLimit,
                  feeRate <= limit
            else {
                throw error
            }
            return try unsignedTransaction(psbtData: psbtData)
        }
    }

    static func unsignedTransaction(psbtData: Data) throws -> BitcoinDevKit.Transaction {
        let transactionBytes = try PsbtKeyValueMap.unsignedTransactionBytes(psbtData: psbtData)
        return try BitcoinDevKit.Transaction(transactionBytes: transactionBytes)
    }

    static func spendingUtxo(psbtInput: BitcoinDevKit.Input, vout: UInt32) throws -> BitcoinDevKit.TxOut {
        if let witness = psbtInput.witnessUtxo {
            return witness
        }

        if let nonWitness = psbtInput.nonWitnessUtxo {
            let outputs = nonWitness.output()
            guard outputs.indices.contains(Int(vout)) else {
                throw BlockchainSdk.BitcoinError.invalidPsbt("nonWitnessUtxo output index out of range")
            }
            return outputs[Int(vout)]
        }

        throw BlockchainSdk.BitcoinError.missingUtxo(Int(vout))
    }
}

extension BitcoinPsbtSigningBuilder {
    /// A copy of the (already finalized) PSBT whose per-input `witness_utxo` values are replaced
    /// so that total inputs equal total outputs. Such a copy extracts with zero fee, bypassing the
    /// `AbsurdFeeRate` cap, while `extractTx()` still produces the very same transaction: UTXO
    /// values are metadata and are not part of the extracted bytes.
    /// - Warning: The copy is valid ONLY as `extractTx()` input. Never build sighashes from it:
    ///   the input value is part of the BIP143/FORKID preimage, so the faked values would produce
    ///   signatures the network rejects.
    static func zeroFeeExtractionCopyBase64(psbtData: Data, psbtInputs: [BitcoinDevKit.Input]) throws -> String {
        let tx = try unsignedTransaction(psbtData: psbtData)
        let txInputs = tx.input()

        var psbtMaps: PsbtKeyValueMap
        do {
            psbtMaps = try PsbtKeyValueMap(data: psbtData, inputCount: txInputs.count, outputCount: tx.output().count)
        } catch {
            throw BlockchainSdk.BitcoinError.invalidPsbt(String(describing: error))
        }

        let totalOut = try tx.output().reduce(UInt64(0)) { try addOrThrow($0, $1.value.toSat()) }

        for index in txInputs.indices {
            let utxo = try spendingUtxo(psbtInput: psbtInputs[index], vout: txInputs[index].previousOutput.vout)
            try psbtMaps.setWitnessUtxo(
                inputIndex: index,
                value: index == 0 ? totalOut : 0,
                scriptPubKey: utxo.scriptPubkey.toBytes()
            )
        }

        return psbtMaps.serialize().base64EncodedString()
    }

    static func addOrThrow(_ lhs: UInt64, _ rhs: UInt64) throws -> UInt64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        guard !overflow else {
            throw BlockchainSdk.BitcoinError.invalidPsbt("Satoshi amounts total overflows UInt64")
        }
        return sum
    }
}

public extension BitcoinPsbtSigningBuilder {
    struct SignInput: Hashable, Sendable {
        public let index: Int

        public init(index: Int) {
            self.index = index
        }
    }
}
