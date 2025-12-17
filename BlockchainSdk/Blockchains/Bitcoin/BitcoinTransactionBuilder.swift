//
//  BitcoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore
import BitcoinDevKit

/// Decoder:
/// https://learnmeabitcoin.com/tools/
/// https://www.blockchain.com/explorer/assets/btc/decode-transaction
class BitcoinTransactionBuilder {
    private let network: UTXONetworkParams
    private let unspentOutputManager: UnspentOutputManager
    private let builderType: BuilderType
    private let sequence: SequenceType

    private var signHashType: UTXONetworkParamsSignHashType { network.signHashType }

    init(
        network: UTXONetworkParams,
        unspentOutputManager: UnspentOutputManager,
        builderType: BuilderType,
        sequence: SequenceType = .rbf
    ) {
        self.network = network
        self.unspentOutputManager = unspentOutputManager
        self.builderType = builderType
        self.sequence = sequence
    }

    func fee(amount: Amount, address: String, feeRate: Int) async throws -> Int {
        let satoshi = amount.asSmallest().value.intValue()
        let preImage = try await unspentOutputManager.preImage(amount: satoshi, feeRate: feeRate, destination: address)
        return preImage.fee
    }

    func buildForSign(transaction: Transaction) async throws -> [Data] {
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)
        let possibleToUseWalletCore = try possibleToUseWalletCore(for: preImage)

        let hashes: [Data] = try {
            switch builderType {
            case .walletCore(let coinType) where possibleToUseWalletCore:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.preImageHashes(transaction: (transaction: transaction, preImage: preImage))
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.preImageHashes(transaction: preImage)
            }
        }()

        return hashes
    }

    func buildForSend(transaction: Transaction, signatures: [SignatureInfo]) async throws -> Data {
        let preImage = try await unspentOutputManager.preImage(transaction: transaction)
        let signatures = try map(scripts: preImage.inputs.map { $0.script }, signatures: signatures)
        let possibleToUseWalletCore = try possibleToUseWalletCore(for: preImage)

        let encoded: Data = try {
            switch builderType {
            case .walletCore(let coinType) where possibleToUseWalletCore:
                let builderType = WalletCoreUTXOTransactionSerializer(coinType: coinType, sequence: sequence)
                return try builderType.compile(transaction: (transaction: transaction, preImage: preImage), signatures: signatures)
            case .custom, .walletCore:
                let builderType = CommonUTXOTransactionSerializer(sequence: sequence, signHashType: signHashType)
                return try builderType.compile(transaction: preImage, signatures: signatures)
            }
        }()

        return encoded
    }
}

// MARK: - Private

private extension BitcoinTransactionBuilder {
    func map(scripts: [UTXOLockingScript], signatures: [SignatureInfo]) throws -> [SignatureInfo] {
        guard scripts.count == signatures.count else {
            throw Error.wrongSignaturesCount
        }

        return try zip(scripts, signatures).map { script, signature in
            let publicKey: Data = try {
                switch script.spendable {
                // If we're spending an output which was received on address which was generated for the compressed public key,
                // we need to `compress()` the public key that was used for signing
                case .publicKey(let publicKey) where Secp256k1Key.isCompressed(publicKey: publicKey):
                    return try Secp256k1Key(with: signature.publicKey).compress()

                case .publicKey(let publicKey):
                    return publicKey

                // The redeemScript is used only for Twin cards
                // We always use the compressed public key from `SignatureInfo`
                // This is important to identify which of the two cards was used for signing
                case .redeemScript:
                    return try Secp256k1Key(with: signature.publicKey).compress()

                case .none:
                    throw UTXOTransactionSerializerError.spendableScriptNotFound
                }
            }()

            return try SignatureInfo(signature: signature.der(), publicKey: publicKey, hash: signature.hash)
        }
    }

    // The WalletCoreUTXOTransactionSerializer supports only compressed publicKey
    // [REDACTED_TODO_COMMENT]
    func possibleToUseWalletCore(for preImage: PreImageTransaction) throws -> Bool {
        let hasExtendedPublicKey = try preImage.inputs.contains { input in
            switch input.script.spendable {
            case .none: throw UTXOTransactionSerializerError.spendableScriptNotFound
            case .publicKey(let data): Secp256k1Key.isExtended(publicKey: data)
            case .redeemScript: false
            }
        }

        return !hasExtendedPublicKey
    }
}

extension BitcoinTransactionBuilder {
    enum Error: LocalizedError {
        case wrongSignaturesCount

        var errorDescription: String? {
            switch self {
            case .wrongSignaturesCount: "Wrong signatures count"
            }
        }
    }
}

extension BitcoinTransactionBuilder {
    enum BuilderType {
        case walletCore(CoinType)
        case custom
    }
}

// MARK: - PSBT signing (WalletConnect)

/// Minimal PSBT (BIP174) signing helper for BTC-style transactions (p2pkh + p2wpkh, SIGHASH_ALL only).
/// Designed to be reused by app-layer features (e.g. WalletConnect) without pulling BitcoinDevKit into `BlockchainSdk`.
public enum BitcoinPsbtSigningBuilder {
    public struct SignInput: Hashable, Sendable {
        public let index: Int

        public init(index: Int) {
            self.index = index
        }
    }

    public enum Error: Swift.Error {
        case invalidBase64
        case invalidPsbt(String)
        case unsupported(String)
        case inputIndexOutOfRange(Int)
        case missingUtxo(Int)
        case wrongSignaturesCount
    }

    /// Build hashes that must be signed for the given PSBT inputs (sorted by index).
    /// - Note: Returned hashes are double-SHA256 preimages for BTC SIGHASH_ALL.
    public static func hashesToSign(psbtBase64: String, signInputs: [SignInput]) throws -> [Data] {
        guard Data(base64Encoded: psbtBase64) != nil else {
            throw Error.invalidBase64
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
            throw Error.invalidBase64
        }

        let bdkPsbt = try Psbt(psbtBase64: psbtBase64)
        let tx = try bdkPsbt.extractTx()
        let inputCount = tx.input().count
        let outputCount = tx.output().count
        var psbt = try PsbtKeyValueMaps(data: psbtData, inputCount: inputCount, outputCount: outputCount)

        let indices = signInputs.map(\.index).sorted()
        guard indices.count == signatures.count else {
            throw Error.wrongSignaturesCount
        }

        for (i, inputIndex) in indices.enumerated() {
            guard inputIndex >= 0, inputIndex < inputCount else {
                throw Error.inputIndexOutOfRange(inputIndex)
            }

            // PSBT partial sigs expect DER signature + 1-byte sighash type.
            let der = try signatures[i].der()
            let sigWithHashType = der + Data([0x01]) // SIGHASH_ALL

            try psbt.setPartialSignature(inputIndex: inputIndex, publicKey: publicKey, signatureWithSighash: sigWithHashType)
        }

        let signedBase64 = psbt.serialize().base64EncodedString()
        let bdkSigned = try Psbt(psbtBase64: signedBase64)
        let finalized = bdkSigned.finalize()

        guard finalized.couldFinalize else {
            throw Error.invalidPsbt("Could not finalize PSBT")
        }

        return finalized.psbt.serialize()
    }
}

// MARK: - PSBT internals (BIP174)

private struct PsbtKeyValueMaps {
    private(set) var globalMap: [KV]
    private(set) var inputMaps: [[KV]]
    private(set) var outputMaps: [[KV]]

    init(data: Data, inputCount: Int, outputCount: Int) throws {
        var reader = ByteReader(data)
        let magic = try reader.read(count: 5)
        guard magic == Data([0x70, 0x73, 0x62, 0x74, 0xff]) else {
            throw BitcoinPsbtSigningBuilder.Error.invalidPsbt("Invalid PSBT magic")
        }

        globalMap = try reader.readKVMap()
        inputMaps = try (0 ..< inputCount).map { _ in try reader.readKVMap() }
        outputMaps = try (0 ..< outputCount).map { _ in try reader.readKVMap() }
    }

    mutating func setPartialSignature(inputIndex: Int, publicKey: Data, signatureWithSighash: Data) throws {
        try setInputKV(inputIndex: inputIndex, key: Data([KeyType.inputPartialSig]) + publicKey, value: signatureWithSighash)
    }

    func serialize() -> Data {
        var data = Data([0x70, 0x73, 0x62, 0x74, 0xff])
        data.append(serializeKVMap(globalMap))
        for map in inputMaps {
            data.append(serializeKVMap(map))
        }
        for map in outputMaps {
            data.append(serializeKVMap(map))
        }
        return data
    }

    // MARK: - Private

    private mutating func setInputKV(inputIndex: Int, key: Data, value: Data) throws {
        guard inputMaps.indices.contains(inputIndex) else {
            throw BitcoinPsbtSigningBuilder.Error.inputIndexOutOfRange(inputIndex)
        }
        setInputKVNoThrow(inputIndex: inputIndex, key: key, value: value)
    }

    private mutating func setInputKVNoThrow(inputIndex: Int, key: Data, value: Data) {
        var map = inputMaps[inputIndex]
        let kv = KV(key: key, value: value)
        if let idx = map.firstIndex(where: { $0.key == key }) {
            map[idx] = kv
        } else {
            map.append(kv)
        }
        map.sort(by: { $0.key.lexicographicallyPrecedes($1.key) })
        inputMaps[inputIndex] = map
    }

    private mutating func removeInputKVNoThrow(inputIndex: Int, key: Data) {
        guard inputMaps.indices.contains(inputIndex) else { return }
        var map = inputMaps[inputIndex]
        map.removeAll(where: { $0.key == key })
        inputMaps[inputIndex] = map
    }

    private func serializeKVMap(_ map: [KV]) -> Data {
        var data = Data()
        for kv in map.sorted(by: { $0.key.lexicographicallyPrecedes($1.key) }) {
            data.append(VarInt.encode(UInt64(kv.key.count)))
            data.append(kv.key)
            data.append(VarInt.encode(UInt64(kv.value.count)))
            data.append(kv.value)
        }
        data.append(0x00)
        return data
    }

    struct KV: Hashable {
        let key: Data
        let value: Data
    }

    enum KeyType {
        static let globalUnsignedTx: UInt8 = 0x00
        static let inputPartialSig: UInt8 = 0x02
    }
}

// MARK: - Script + sighash (SIGHASH_ALL)

private enum ScriptType {
    case p2pkh
    case p2wpkh
    case unsupported(String)

    init(scriptPubKey: Data) {
        if scriptPubKey.count == 22, scriptPubKey[0] == 0x00, scriptPubKey[1] == 0x14 {
            self = .p2wpkh
            return
        }

        if scriptPubKey.count == 25,
           scriptPubKey[0] == 0x76,
           scriptPubKey[1] == 0xA9,
           scriptPubKey[2] == 0x14,
           scriptPubKey[23] == 0x88,
           scriptPubKey[24] == 0xAC {
            self = .p2pkh
            return
        }

        self = .unsupported("Unsupported scriptPubKey (len=\(scriptPubKey.count))")
    }
}

private func sighashAll(
    tx: BitcoinDevKit.Transaction,
    txInputs: [BitcoinDevKit.TxIn],
    txOutputs: [BitcoinDevKit.TxOut],
    psbtInputs: [BitcoinDevKit.Input],
    inputIndex: Int
) throws -> Data {
    guard txInputs.indices.contains(inputIndex) else {
        throw BitcoinPsbtSigningBuilder.Error.inputIndexOutOfRange(inputIndex)
    }

    guard psbtInputs.indices.contains(inputIndex) else {
        throw BitcoinPsbtSigningBuilder.Error.inputIndexOutOfRange(inputIndex)
    }

    let outpoint = txInputs[inputIndex].previousOutput
    let utxo = try spendingUtxo(psbtInput: psbtInputs[inputIndex], vout: outpoint.vout)
    let scriptPubKey = utxo.scriptPubkey.toBytes()
    let scriptType = ScriptType(scriptPubKey: scriptPubKey)

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
        throw BitcoinPsbtSigningBuilder.Error.unsupported(reason)
    }
}

private func spendingUtxo(psbtInput: BitcoinDevKit.Input, vout: UInt32) throws -> BitcoinDevKit.TxOut {
    if let witness = psbtInput.witnessUtxo {
        return witness
    }

    if let nonWitness = psbtInput.nonWitnessUtxo {
        let outputs = nonWitness.output()
        guard outputs.indices.contains(Int(vout)) else {
            throw BitcoinPsbtSigningBuilder.Error.invalidPsbt("nonWitnessUtxo output index out of range")
        }
        return outputs[Int(vout)]
    }

    throw BitcoinPsbtSigningBuilder.Error.missingUtxo(Int(vout))
}

// finalScriptSig / finalScriptWitness are produced by `BitcoinDevKit.Psbt.finalize()`

// MARK: - Low-level readers/writers

private struct ByteReader {
    private let data: Data
    private var offset: Int = 0

    init(_ data: Data) {
        self.data = data
    }

    mutating func read(count: Int) throws -> Data {
        guard offset + count <= data.count else {
            throw BitcoinPsbtSigningBuilder.Error.invalidPsbt("Unexpected EOF")
        }
        defer { offset += count }
        return data.subdata(in: offset ..< offset + count)
    }

    mutating func readUInt32LE() throws -> UInt32 {
        let d = try read(count: 4)
        return UInt32(littleEndian: d.withUnsafeBytes { $0.load(as: UInt32.self) })
    }

    mutating func readUInt64LE() throws -> UInt64 {
        let d = try read(count: 8)
        return UInt64(littleEndian: d.withUnsafeBytes { $0.load(as: UInt64.self) })
    }

    mutating func readVarInt() throws -> UInt64 {
        let first = try read(count: 1).first!
        switch first {
        case 0x00 ... 0xFC:
            return UInt64(first)
        case 0xFD:
            let d = try read(count: 2)
            return UInt64(UInt16(littleEndian: d.withUnsafeBytes { $0.load(as: UInt16.self) }))
        case 0xFE:
            return UInt64(try readUInt32LE())
        case 0xFF:
            return try readUInt64LE()
        default:
            throw BitcoinPsbtSigningBuilder.Error.invalidPsbt("Invalid varint")
        }
    }

    mutating func readVarBytes() throws -> Data {
        let len = Int(try readVarInt())
        return try read(count: len)
    }

    mutating func readKVMap() throws -> [PsbtKeyValueMaps.KV] {
        var items: [PsbtKeyValueMaps.KV] = []
        while true {
            let keyLen = try readVarInt()
            if keyLen == 0 { break }
            let key = try read(count: Int(keyLen))
            let valueLen = try readVarInt()
            let value = try read(count: Int(valueLen))
            items.append(.init(key: key, value: value))
        }
        return items
    }
}

private enum VarInt {
    static func encode(_ value: UInt64) -> Data {
        switch value {
        case 0 ..< 0xFD:
            return Data([UInt8(value)])
        case 0xFD ..< 0x1_0000:
            var v = UInt16(value).littleEndian
            return Data([0xFD]) + withUnsafeBytes(of: &v) { Data($0) }
        case 0x1_0000 ..< 0x1_0000_0000:
            var v = UInt32(value).littleEndian
            return Data([0xFE]) + withUnsafeBytes(of: &v) { Data($0) }
        default:
            var v = UInt64(value).littleEndian
            return Data([0xFF]) + withUnsafeBytes(of: &v) { Data($0) }
        }
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var v = littleEndian
        return withUnsafeBytes(of: &v) { Data($0) }
    }
}
