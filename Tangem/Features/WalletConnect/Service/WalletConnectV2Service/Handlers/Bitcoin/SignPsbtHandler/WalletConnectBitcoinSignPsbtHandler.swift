//
//  WalletConnectBitcoinSignPsbtHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Commons
import enum JSONRPC.RPCResult
import BitcoinDevKit
import BlockchainSdk
import CryptoSwift

/// Handler for BTC signPsbt RPC method.
final class WalletConnectBitcoinSignPsbtHandler {
    private let request: AnyCodable
    private let walletModel: any WalletModel
    private let signer: TangemSigner
    private let parsedRequest: WalletConnectBtcSignPsbtRequest
    private let encoder = JSONEncoder()

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        walletModelProvider: WalletConnectWalletModelProvider
    ) throws {
        do {
            parsedRequest = try request.get(WalletConnectBtcSignPsbtRequest.self)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.description)
        }

        guard let model = walletModelProvider.getModel(with: blockchainId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        walletModel = model
        self.request = request
        self.signer = signer
    }

    init(
        request: AnyCodable,
        blockchainId: String,
        signer: TangemSigner,
        wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider,
        accountId: String
    ) throws {
        do {
            parsedRequest = try request.get(WalletConnectBtcSignPsbtRequest.self)
        } catch {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(request.description)
        }

        guard let model = wcAccountsWalletModelProvider.getModel(with: blockchainId, accountId: accountId) else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        walletModel = model
        self.request = request
        self.signer = signer
    }
}

// MARK: - WalletConnectMessageHandler

extension WalletConnectBitcoinSignPsbtHandler: WalletConnectMessageHandler {
    var method: WalletConnectMethod { .signPsbt }

    var rawTransaction: String? {
        request.stringRepresentation
    }

    var requestData: Data {
        (try? encoder.encode(parsedRequest)) ?? Data()
    }

    func validate() async throws -> WalletConnectMessageHandleRestrictionType {
        // Only 0 or 1 sighashTypes per input is supported for now
        if let badInput = parsedRequest.signInputs.first(where: { ($0.sighashTypes?.count ?? 0) > 1 }) {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(
                "Multiple sighashTypes are not supported. index=\(badInput.index)"
            )
        }

        return .empty
    }

    func handle() async throws -> RPCResult {
        if parsedRequest.broadcast == true {
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod("signPsbt broadcast")
        }

        let signedPsbtBase64 = try await sign()
        let response = WalletConnectBtcSignPsbtResponse(psbt: signedPsbtBase64, txid: nil)
        return .response(AnyCodable(response))
    }
}

// MARK: - Signing

private extension WalletConnectBitcoinSignPsbtHandler {
    func sign() async throws -> String {
        let unsignedTx = try extractUnsignedTransaction(from: parsedRequest.psbt)

        // Only sign requested inputs
        guard !parsedRequest.signInputs.isEmpty else {
            return parsedRequest.psbt
        }

        let psbtData = try Data(base64Encoded: parsedRequest.psbt).unwrapOrThrow(
            WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid PSBT base64")
        )

        var parsed = try PSBT(data: psbtData)

        // Prepare hashes in original order for multi-sign (one tap)
        let inputsToSign = parsedRequest.signInputs.sorted(by: { $0.index < $1.index })

        let hashesToSign: [Data] = try inputsToSign.map { input in
            let sighashType = input.sighashTypes?.first ?? SighashType.all.rawValue
            return try computeSighash(
                unsignedTx: unsignedTx,
                psbt: parsed,
                inputIndex: input.index,
                sighashType: sighashType
            )
        }

        let signatures = try await signDER(hashes: hashesToSign)

        // Insert partial signatures
        let pubKey = try signingPublicKey(for: inputsToSign)
        for (requestInput, derSignature) in zip(inputsToSign, signatures) {
            let sighashType = requestInput.sighashTypes?.first ?? SighashType.all.rawValue
            let sigWithHashType = derSignature + Data([UInt8(truncatingIfNeeded: sighashType)])
            try parsed.insertPartialSignature(
                inputIndex: requestInput.index,
                publicKey: pubKey,
                signatureWithSighash: sigWithHashType
            )
        }

        // Finalize PSBT (build finalScriptSig/finalScriptWitness) so dApps don't treat it as "Not finalized".
        let signedBase64 = parsed.serialize().base64EncodedString()
        let bdkPsbt = try Psbt(psbtBase64: signedBase64)
        let finalized = bdkPsbt.finalize()

        guard finalized.couldFinalize else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(
                "PSBT could not be finalized: \(finalized.errors?.localizedDescription ?? "unknown error")"
            )
        }

        return finalized.psbt.serialize()
    }

    func extractUnsignedTransaction(from psbtBase64: String) throws -> BitcoinUnsignedTransaction {
        let data = try Data(base64Encoded: psbtBase64).unwrapOrThrow(
            WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid PSBT base64")
        )

        let psbt = try PSBT(data: data)
        return try BitcoinUnsignedTransaction(data: psbt.unsignedTransaction)
    }

    func signingPublicKey(for inputs: [WalletConnectBtcPsbtSignInput]) throws -> Data {
        // WC spec provides `address` per input. We validate it's one of our wallet addresses.
        for input in inputs {
            let matches = walletModel.addresses.contains(where: { $0.value.caseInsensitiveCompare(input.address) == .orderedSame })
            guard matches else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("Unknown address for signing: \(input.address)")
            }
        }

        // Use walletModel public key as signer key.
        // BDK uses hex-encoded pubkey string as map key; we store raw bytes here.
        return walletModel.publicKey.blockchainKey
    }

    func signDER(hashes: [Data]) async throws -> [Data] {
        let pubKey = walletModel.publicKey

        let signed = try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()

        return try signed.map { signatureInfo in
            // PSBT expects DER-encoded ECDSA signature (without sighash byte).
            // `SignatureInfo.der()` serializes the raw signature to DER using `Secp256k1Utils`.
            try signatureInfo.der()
        }
    }

    func computeSighash(
        unsignedTx: BitcoinUnsignedTransaction,
        psbt: PSBT,
        inputIndex: Int,
        sighashType: Int
    ) throws -> Data {
        guard unsignedTx.inputs.indices.contains(inputIndex) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Input index out of range: \(inputIndex)")
        }

        let utxo = try psbt.spendUTXO(forInputIndex: inputIndex)
        let scriptType = try ScriptType(scriptPubKey: utxo.scriptPubKey)

        switch scriptType {
        case .p2wpkh:
            let pubKeyHash = utxo.scriptPubKey.subdata(in: 2 ..< 22)
            return try Sighash.v0Witness(
                tx: unsignedTx,
                inputIndex: inputIndex,
                scriptCode: ScriptCode.p2pkh(pubKeyHash: pubKeyHash),
                value: utxo.value,
                sighashType: UInt32(sighashType)
            )
        case .p2pkh:
            return try Sighash.legacy(
                tx: unsignedTx,
                inputIndex: inputIndex,
                scriptCode: utxo.scriptPubKey,
                sighashType: UInt32(sighashType)
            )
        case .unsupported(let reason):
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod("signPsbt \(reason)")
        }
    }
}

// MARK: - Minimal PSBT implementation (BIP174)

private struct PSBT {
    let unsignedTransaction: Data
    private(set) var globalMap: [KV]
    private(set) var inputMaps: [[KV]]
    private(set) var outputMaps: [[KV]]

    init(data: Data) throws {
        var reader = ByteReader(data)

        let magic = try reader.read(count: 5)
        guard magic == Data([0x70, 0x73, 0x62, 0x74, 0xff]) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid PSBT magic")
        }

        globalMap = try reader.readKVMap()
        guard let unsignedTxKV = globalMap.first(where: { $0.key.first == PSBTKeyType.globalUnsignedTx }) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("PSBT missing unsigned tx")
        }
        unsignedTransaction = unsignedTxKV.value

        // Determine input/output counts from unsigned transaction
        let tx = try BitcoinUnsignedTransaction(data: unsignedTransaction)
        inputMaps = try (0 ..< tx.inputs.count).map { _ in try reader.readKVMap() }
        outputMaps = try (0 ..< tx.outputs.count).map { _ in try reader.readKVMap() }
    }

    mutating func insertPartialSignature(inputIndex: Int, publicKey: Data, signatureWithSighash: Data) throws {
        guard inputMaps.indices.contains(inputIndex) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Input index out of range: \(inputIndex)")
        }

        let key = Data([PSBTKeyType.inputPartialSig]) + publicKey
        let kv = KV(key: key, value: signatureWithSighash)

        // Replace existing if any, else insert and keep map sorted by key bytes.
        var map = inputMaps[inputIndex]
        if let idx = map.firstIndex(where: { $0.key == key }) {
            map[idx] = kv
        } else {
            map.append(kv)
        }
        map.sort(by: { $0.key.lexicographicallyPrecedes($1.key) })
        inputMaps[inputIndex] = map
    }

    func spendUTXO(forInputIndex index: Int) throws -> UTXO {
        guard inputMaps.indices.contains(index) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Input index out of range: \(index)")
        }

        let map = inputMaps[index]
        if let witnessUtxoKV = map.first(where: { $0.key.first == PSBTKeyType.inputWitnessUtxo }) {
            // value is TxOut serialization: 8-byte value + varint scriptLen + script
            var reader = ByteReader(witnessUtxoKV.value)
            let value = try reader.readUInt64LE()
            let script = try reader.readVarBytes()
            return UTXO(value: value, scriptPubKey: script)
        }

        if let nonWitnessUtxoKV = map.first(where: { $0.key.first == PSBTKeyType.inputNonWitnessUtxo }) {
            // value is full previous tx serialization, need referenced vout from unsigned tx input
            let prevTx = try BitcoinUnsignedTransaction(data: nonWitnessUtxoKV.value)
            // We need the outpoint.vout from the unsigned tx itself
            let unsignedTx = try BitcoinUnsignedTransaction(data: unsignedTransaction)
            let vout = unsignedTx.inputs[index].vout
            guard prevTx.outputs.indices.contains(Int(vout)) else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("nonWitnessUtxo output index out of range")
            }
            let out = prevTx.outputs[Int(vout)]
            return UTXO(value: out.value, scriptPubKey: out.scriptPubKey)
        }

        throw WalletConnectTransactionRequestProcessingError.invalidPayload("Missing UTXO for input \(index)")
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

    private func serializeKVMap(_ map: [KV]) -> Data {
        var data = Data()
        for kv in map.sorted(by: { $0.key.lexicographicallyPrecedes($1.key) }) {
            data.append(VarInt.encode(kv.key.count))
            data.append(kv.key)
            data.append(VarInt.encode(kv.value.count))
            data.append(kv.value)
        }
        data.append(0x00) // separator
        return data
    }

    struct KV: Hashable {
        let key: Data
        let value: Data
    }

    struct UTXO {
        let value: UInt64
        let scriptPubKey: Data
    }

    enum PSBTKeyType {
        static let globalUnsignedTx: UInt8 = 0x00
        static let inputNonWitnessUtxo: UInt8 = 0x00
        static let inputWitnessUtxo: UInt8 = 0x01
        static let inputPartialSig: UInt8 = 0x02
    }
}

private struct ByteReader {
    private let data: Data
    private var offset: Int = 0

    init(_ data: Data) {
        self.data = data
    }

    mutating func read(count: Int) throws -> Data {
        guard offset + count <= data.count else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Unexpected EOF")
        }
        defer { offset += count }
        return data.subdata(in: offset ..< offset + count)
    }

    mutating func readByte() throws -> UInt8 {
        let d = try read(count: 1)
        return d[d.startIndex]
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
        let first = try readByte()
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
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid varint")
        }
    }

    mutating func readVarBytes() throws -> Data {
        let len = Int(try readVarInt())
        return try read(count: len)
    }

    mutating func readKVMap() throws -> [PSBT.KV] {
        var items: [PSBT.KV] = []
        while true {
            let keyLen = try readVarInt()
            if keyLen == 0 {
                break
            }
            let key = try read(count: Int(keyLen))
            let valueLen = try readVarInt()
            let value = try read(count: Int(valueLen))
            items.append(PSBT.KV(key: key, value: value))
        }
        return items
    }
}

private enum VarInt {
    static func encode(_ value: Int) -> Data {
        encode(UInt64(value))
    }

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

// MARK: - Minimal unsigned transaction parser

private struct BitcoinUnsignedTransaction {
    let version: UInt32
    let inputs: [Input]
    let outputs: [Output]
    let lockTime: UInt32

    init(data: Data) throws {
        var r = ByteReader(data)
        version = try r.readUInt32LE()

        // PSBT unsigned tx must be non-witness serialization, so next is input count.
        let inputCount = Int(try r.readVarInt())
        inputs = try (0 ..< inputCount).map { _ in
            let prevTxidLE = try r.read(count: 32)
            let vout = try r.readUInt32LE()
            _ = try r.readVarBytes() // scriptSig
            let sequence = try r.readUInt32LE()
            return Input(prevTxidLE: prevTxidLE, vout: vout, sequence: sequence)
        }

        let outputCount = Int(try r.readVarInt())
        outputs = try (0 ..< outputCount).map { _ in
            let value = try r.readUInt64LE()
            let script = try r.readVarBytes()
            return Output(value: value, scriptPubKey: script)
        }

        lockTime = try r.readUInt32LE()
    }

    struct Input {
        let prevTxidLE: Data
        let vout: UInt32
        let sequence: UInt32
    }

    struct Output {
        let value: UInt64
        let scriptPubKey: Data
    }
}

// MARK: - Sighash

private enum SighashType: Int {
    case all = 0x01
}

private enum ScriptType {
    case p2pkh
    case p2wpkh
    case unsupported(String)

    init(scriptPubKey: Data) throws {
        // p2wpkh: 0x00 0x14 <20>
        if scriptPubKey.count == 22, scriptPubKey[0] == 0x00, scriptPubKey[1] == 0x14 {
            self = .p2wpkh
            return
        }

        // p2pkh: 76 a9 14 <20> 88 ac
        if scriptPubKey.count == 25,
           scriptPubKey[0] == 0x76,
           scriptPubKey[1] == 0xA9,
           scriptPubKey[2] == 0x14,
           scriptPubKey[23] == 0x88,
           scriptPubKey[24] == 0xAC {
            self = .p2pkh
            return
        }

        self = .unsupported("unsupported scriptPubKey=\(scriptPubKey.toHexString())")
    }
}

private enum ScriptCode {
    static func p2pkh(pubKeyHash: Data) -> Data {
        // OP_DUP OP_HASH160 push(20) <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
        Data([0x76, 0xA9, 0x14]) + pubKeyHash + Data([0x88, 0xAC])
    }
}

private enum Sighash {
    static func legacy(tx: BitcoinUnsignedTransaction, inputIndex: Int, scriptCode: Data, sighashType: UInt32) throws -> Data {
        var preimage = Data()
        preimage.append(tx.version.littleEndianData)
        preimage.append(VarInt.encode(UInt64(tx.inputs.count)))

        for (idx, inp) in tx.inputs.enumerated() {
            preimage.append(inp.prevTxidLE)
            preimage.append(inp.vout.littleEndianData)
            if idx == inputIndex {
                preimage.append(VarInt.encode(UInt64(scriptCode.count)))
                preimage.append(scriptCode)
            } else {
                preimage.append(0x00)
            }
            preimage.append(inp.sequence.littleEndianData)
        }

        preimage.append(VarInt.encode(UInt64(tx.outputs.count)))
        for out in tx.outputs {
            preimage.append(out.value.littleEndianData)
            preimage.append(VarInt.encode(UInt64(out.scriptPubKey.count)))
            preimage.append(out.scriptPubKey)
        }

        preimage.append(tx.lockTime.littleEndianData)
        preimage.append(sighashType.littleEndianData)

        return preimage.sha256().sha256()
    }

    static func v0Witness(
        tx: BitcoinUnsignedTransaction,
        inputIndex: Int,
        scriptCode: Data,
        value: UInt64,
        sighashType: UInt32
    ) throws -> Data {
        var preimage = Data()
        preimage.append(tx.version.littleEndianData)

        // hashPrevouts
        var prevouts = Data()
        for inp in tx.inputs {
            prevouts.append(inp.prevTxidLE)
            prevouts.append(inp.vout.littleEndianData)
        }
        preimage.append(prevouts.sha256().sha256())

        // hashSequence
        var sequences = Data()
        for inp in tx.inputs {
            sequences.append(inp.sequence.littleEndianData)
        }
        preimage.append(sequences.sha256().sha256())

        let inp = tx.inputs[inputIndex]
        preimage.append(inp.prevTxidLE)
        preimage.append(inp.vout.littleEndianData)

        preimage.append(VarInt.encode(UInt64(scriptCode.count)))
        preimage.append(scriptCode)

        preimage.append(value.littleEndianData)
        preimage.append(inp.sequence.littleEndianData)

        // hashOutputs
        var outs = Data()
        for out in tx.outputs {
            outs.append(out.value.littleEndianData)
            outs.append(VarInt.encode(UInt64(out.scriptPubKey.count)))
            outs.append(out.scriptPubKey)
        }
        preimage.append(outs.sha256().sha256())

        preimage.append(tx.lockTime.littleEndianData)
        preimage.append(sighashType.littleEndianData)

        return preimage.sha256().sha256()
    }
}

private extension FixedWidthInteger {
    var littleEndianData: Data {
        var v = littleEndian
        return withUnsafeBytes(of: &v) { Data($0) }
    }
}

private extension Optional {
    func unwrapOrThrow(_ error: Error) throws -> Wrapped {
        switch self {
        case .some(let v): return v
        case .none: throw error
        }
    }
}

private extension Array where Element: LocalizedError {
    var localizedDescription: String {
        map { $0.errorDescription ?? String(describing: $0) }.joined(separator: ", ")
    }
}

// MARK: - Models

struct WalletConnectBtcSignPsbtRequest: Codable {
    let psbt: String
    let signInputs: [WalletConnectBtcPsbtSignInput]
    let broadcast: Bool?
}

struct WalletConnectBtcPsbtSignInput: Codable {
    let address: String
    let index: Int
    let sighashTypes: [Int]?
}

struct WalletConnectBtcSignPsbtResponse: Codable {
    let psbt: String
    let txid: String?
}
