//
//  CommonUTXOTransactionSerializer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CommonUTXOTransactionSerializer {
    typealias Transaction = (transaction: BlockchainSdk.Transaction, preImage: PreImageTransaction)

    let version: UInt32
    let sequence: SequenceType
    let locktime: UInt32 = .zero
    let signHashType: UTXONetworkParamsSignHashType

    init(version: UInt32 = 1, sequence: SequenceType, signHashType: UTXONetworkParamsSignHashType = .bitcoinAll) {
        self.version = version
        self.sequence = sequence
        self.signHashType = signHashType
    }
}

// MARK: - UTXOTransactionSerializer

extension CommonUTXOTransactionSerializer: UTXOTransactionSerializer {
    func preImageHashes(transaction: Transaction) throws -> [Data] {
        let hashes = try transaction.preImage.inputs.indexed().map { index, input in
            if input.script.type.isWitness || signHashType == .bitcoinCashAll {
                return try bip143PreImageHash(transaction: transaction, inputIndex: index)
            }

            return try preImageHash(transaction: transaction, inputIndex: index)
        }

        return hashes
    }

    func compile(transaction: Transaction, signatures: [SignatureInfo]) throws -> Data {
        try encode(transaction: transaction, signatures: signatures)
    }
}

// MARK: - Serialization

private extension CommonUTXOTransactionSerializer {
    func encode(transaction: Transaction, signatures: [SignatureInfo]) throws -> Data {
        var bytes = Data()

        // Version
        bytes += version.data

        let opReturnOutput = try opReturnOutput(from: transaction.transaction)

        if transaction.preImage.isWitness {
            // Marker
            bytes += UInt8(0).data
            // Flag
            bytes += UInt8(1).data
        }

        // Inputs
        bytes += transaction.preImage.inputs.count.byte
        zip(transaction.preImage.inputs, signatures).forEach { input, signature in
            bytes += encodeInput(input, script: input.script.type.isWitness ? .blank : .signed(signature))
        }

        // Outputs
        let outputsCount = transaction.preImage.outputs.count + (opReturnOutput == nil ? 0 : 1)
        bytes += outputsCount.byte
        transaction.preImage.outputs.forEach { output in
            bytes += encodeOutput(output)
        }
        if let opReturnOutput {
            bytes += opReturnOutput
        }

        if transaction.preImage.isWitness {
            try zip(transaction.preImage.inputs, signatures).forEach { input, signature in
                bytes += try encodeWitnessInput(input, signature: signature.signature)
            }
        }

        bytes += locktime.data
        return bytes
    }

    enum InputScriptSigType {
        case toBeSigned(lockingScript: Data)
        case blank
        case signed(SignatureInfo)
    }

    func encodeInput(_ input: ScriptUnspentOutput, script: InputScriptSigType) -> Data {
        var bytes = Data()
        bytes += input.hash.reversed()
        bytes += UInt32(input.index).data

        switch script {
        case .toBeSigned(let lockingScript):
            bytes += lockingScript.count.byte
            bytes += lockingScript
        case .blank:
            bytes += UInt8.zero.data
        case .signed(let signatureInfo):
            var script = Data()
            let signature = signatureInfo.signature + signHashType.value.data
            script += signature.count.byte
            script += signature

            script += signatureInfo.publicKey.count.byte
            script += signatureInfo.publicKey

            bytes += script.count.byte
            bytes += script
        }

        bytes += sequence.value.data
        return bytes
    }

    func encodeOutput(_ output: PreImageTransaction.OutputType) -> Data {
        var bytes = Data()
        bytes += output.value.bytes8LE
        bytes += output.script.data.count.byte
        bytes += output.script.data
        return bytes
    }

    func encodeWitnessInput(_ input: ScriptUnspentOutput, signature: Data) throws -> Data {
        guard input.script.type.isWitness else {
            // Empty witness byte
            return UInt8.zero.data
        }

        guard let spendable = input.script.spendable else {
            throw UTXOTransactionSerializerError.spendableScriptNotFound
        }

        var bytes = Data()

        var data = [OpCode.push(signature + signHashType.value.data), OpCode.push(spendable.data)]
        if input.script.type == .p2wsh {
            // Currently applicable only for `Twin` cards
            data.insert(UInt8.zero.data, at: 0)
        }

        bytes += data.count.byte
        data.forEach { bytes += $0 }
        return bytes
    }

    func opReturnOutput(from transaction: BlockchainSdk.Transaction) throws -> Data? {
        guard let params = transaction.params as? BitcoinTransactionParams else {
            return nil
        }

        guard !params.memo.isEmpty else {
            return nil
        }

        // Standard OP_RETURN relay policy historically limits data to 80 bytes.
        if params.memo.count > 80 {
            throw UTXOTransactionSerializerError.walletCoreError("UTXO memo exceeds 80 bytes")
        }

        // Build locking script: OP_RETURN + push(memo)
        let lockingScript = Data([OpCode.OP_RETURN.value]) + OpCode.push(params.memo)

        // Serialize output: value(8 LE) + scriptLen(varint) + script
        var bytes = Data()
        bytes += UInt64.zero.bytes8LE
        bytes += lockingScript.count.byte
        bytes += lockingScript
        return bytes
    }
}

// MARK: - Digest

private extension CommonUTXOTransactionSerializer {
    /// https://learnmeabitcoin.com/technical/keys/signature/#legacy-algorithm
    func preImageHash(transaction: Transaction, inputIndex: Int) throws -> Data {
        var bytes = Data()

        // Version
        bytes += version.data

        let opReturnOutput = try opReturnOutput(from: transaction.transaction)

        // Inputs
        bytes += transaction.preImage.inputs.count.byte
        transaction.preImage.inputs.enumerated().forEach { index, input in
            let currentInputToBeSigned = inputIndex == index
            bytes += encodeInput(input, script: currentInputToBeSigned ? .toBeSigned(lockingScript: input.script.data) : .blank)
        }

        // Outputs
        let outputsCount = transaction.preImage.outputs.count + (opReturnOutput == nil ? 0 : 1)
        bytes += outputsCount.byte
        transaction.preImage.outputs.forEach { output in
            bytes += encodeOutput(output)
        }
        if let opReturnOutput {
            bytes += opReturnOutput
        }

        bytes += locktime.data
        bytes += UInt32(signHashType.value).data

        return bytes.getDoubleSHA256()
    }

    /// https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki
    /// https://learnmeabitcoin.com/technical/keys/signature/#segwit-algorithm
    func bip143PreImageHash(transaction: Transaction, inputIndex: Int) throws -> Data {
        var bytes = Data()

        // Version
        bytes += version.data

        let opReturnOutput = try opReturnOutput(from: transaction.transaction)

        let prevouts = transaction.preImage.inputs.flatMap { encodeOutPoint($0) }
        bytes += prevouts.getDoubleSHA256()

        let sequences = transaction.preImage.inputs.flatMap { _ in sequence.value.data }
        bytes += sequences.getDoubleSHA256()

        let input = transaction.preImage.inputs[inputIndex]
        bytes += encodeOutPoint(input)

        switch (input.script.type, input.script.spendable) {
        case (.p2wsh, .redeemScript(let redeemScript)):
            bytes += redeemScript.count.byte
            bytes += redeemScript

        case (.p2wpkh, .publicKey(let publicKey)), (.p2pkh, .publicKey(let publicKey)):
            let scriptcode = OpCodeUtils.p2pkh(data: publicKey.sha256Ripemd160)
            bytes += scriptcode.count.byte
            bytes += scriptcode

        case (.p2wsh, _), (.p2wpkh, _):
            throw UTXOTransactionSerializerError.spendableScriptNotFound

        case (.p2tr, _), (.p2pk, _), (.p2pkh, _), (.p2sh, _):
            // Have to be used usual pre image hash
            throw UTXOTransactionSerializerError.unsupported
        }

        bytes += input.amount.data
        bytes += sequence.value.data

        let outputsCount = transaction.preImage.outputs.count + (opReturnOutput == nil ? 0 : 1)
        let outputsBytes = transaction.preImage.outputs.map { encodeOutput($0) } + (opReturnOutput.map { [$0] } ?? [])
        assert(outputsBytes.count == outputsCount)
        bytes += Data(outputsBytes.flatMap(\.self)).getDoubleSHA256()

        bytes += locktime.data
        bytes += UInt32(signHashType.value).data

        return bytes.getDoubleSHA256()
    }

    func encodeOutPoint(_ input: ScriptUnspentOutput) -> Data {
        var bytes = Data()
        bytes += input.hash.reversed()
        bytes += UInt32(input.index).data
        return bytes
    }
}

extension PreImageTransaction {
    var isWitness: Bool {
        inputs.contains(where: { $0.script.type.isWitness })
    }
}
