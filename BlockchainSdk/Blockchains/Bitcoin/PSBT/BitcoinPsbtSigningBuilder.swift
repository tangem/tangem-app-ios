//
//  BitcoinPsbtSigningBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import BitcoinDevKit
import TangemSdk

/// PSBT signing helper for BTC-style transactions (p2pkh + segwit-v0 p2wpkh, SIGHASH_ALL only).
///
/// - Important: BitcoinDevKit Swift bindings do not currently expose mutable PSBT maps.
///   We therefore insert `partial_sigs` via `PsbtKeyValueMap`, then finalize the PSBT via `BitcoinDevKit.Psbt.finalize()`.
public class BitcoinPsbtSigningBuilder {
    /// Build hashes that must be signed for the given PSBT inputs (sorted by index).
    /// - Note: Returned hashes are double-SHA256 for BTC SIGHASH_ALL.
    public static func hashesToSign(psbtBase64: String, signInputs: [SignInput]) throws -> [Data] {
        guard Data(base64Encoded: psbtBase64) != nil else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let psbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try psbt.extractTx()
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
                    inputIndex: index
                )
            )
        }

        return hashes
    }

    /// Apply signatures (in the same order as `signInputs.sorted(by: index)`), finalize inputs and return a base64 PSBT.
    /// - Important: `signatures` must correspond to `hashesToSign` output order.
    public static func applySignaturesAndFinalize(
        psbtBase64: String,
        signInputs: [SignInput],
        signatures: [SignatureInfo],
        publicKey: Data
    ) throws -> String {
        guard let psbtData = Data(base64Encoded: psbtBase64) else {
            throw BlockchainSdk.BitcoinError.invalidBase64
        }

        let bdkPsbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try bdkPsbt.extractTx()
        let inputCount = tx.input().count
        let outputCount = tx.output().count

        var psbtMaps: PsbtKeyValueMap
        do {
            psbtMaps = try PsbtKeyValueMap(data: psbtData, inputCount: inputCount, outputCount: outputCount)
        } catch {
            throw BlockchainSdk.BitcoinError.invalidPsbt(String(describing: error))
        }

        let indices = signInputs.map(\.index).sorted()
        guard indices.count == signatures.count else {
            throw BlockchainSdk.BitcoinError.wrongSignaturesCount
        }

        for (i, inputIndex) in indices.enumerated() {
            guard inputIndex >= 0, inputIndex < inputCount else {
                throw BlockchainSdk.BitcoinError.inputIndexOutOfRange(inputIndex)
            }

            // PSBT partial sigs expect DER signature + 1-byte sighash type.
            let der = try signatures[i].der()
            let sigWithHashType = der + Data([0x01]) // SIGHASH_ALL

            do {
                try psbtMaps.setPartialSignature(
                    inputIndex: inputIndex,
                    publicKey: publicKey,
                    signatureWithSighash: sigWithHashType
                )
            } catch let error as BlockchainSdk.BitcoinError {
                throw BlockchainSdk.BitcoinError.invalidPsbt(error.localizedDescription)
            }
        }

        // Let BitcoinDevKit finalize (fills finalScriptSig/finalScriptWitness when possible).
        let signedBase64 = psbtMaps.serialize().base64EncodedString()
        let bdkSigned = try Psbt(psbtBase64: signedBase64)
        let finalized = bdkSigned.finalize()

        guard finalized.couldFinalize else {
            throw BlockchainSdk.BitcoinError.invalidPsbt("Could not finalize PSBT")
        }

        return finalized.psbt.serialize()
    }
}

// MARK: - Sighash

private extension BitcoinPsbtSigningBuilder {
    static func sighashAll(
        tx: BitcoinDevKit.Transaction,
        txInputs: [BitcoinDevKit.TxIn],
        txOutputs: [BitcoinDevKit.TxOut],
        psbtInputs: [BitcoinDevKit.Input],
        inputIndex: Int
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

        switch scriptType {
        case .p2pkh:
            return try BitcoinSighashBuilder.legacySighashAll(
                version: version,
                lockTime: lockTime,
                inputs: sighashInputs,
                outputs: sighashOutputs,
                inputIndex: inputIndex,
                scriptCode: scriptPubKey
            )
        case .p2wpkh:
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
        case .unsupported(let reason):
            throw BlockchainSdk.BitcoinError.unsupported(reason)
        }
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

public extension BitcoinPsbtSigningBuilder {
    struct SignInput: Hashable, Sendable {
        public let index: Int

        public init(index: Int) {
            self.index = index
        }
    }
}
