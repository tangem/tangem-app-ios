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
        // We currently implement only SIGHASH_ALL for legacy + segwit-v0.
        // WalletConnect can send `sighashTypes` per input; we allow: nil, [], [1]
        if let badInput = parsedRequest.signInputs.first(where: { input in
            guard let types = input.sighashTypes, !types.isEmpty else { return false }
            return !(types.count == 1 && types[0] == SighashType.all.rawValue)
        }) {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Unsupported sighashTypes. index=\(badInput.index)")
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
        let bdkPsbt = try Psbt(psbtBase64: parsedRequest.psbt)
        let tx = try bdkPsbt.extractTx()

        // Only sign requested inputs
        guard !parsedRequest.signInputs.isEmpty else {
            return parsedRequest.psbt
        }

        let psbtData = try Data(base64Encoded: parsedRequest.psbt).unwrapOrThrow(
            WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid PSBT base64")
        )

        let txInputs = tx.input()
        let txOutputs = tx.output()
        let psbtInputs = bdkPsbt.input()

        var psbtMaps = try PsbtKeyValueMaps(
            data: psbtData,
            inputCount: txInputs.count,
            outputCount: txOutputs.count
        )

        // Prepare hashes in original order for multi-sign (one tap)
        let inputsToSign = parsedRequest.signInputs.sorted(by: { $0.index < $1.index })

        let segwitV0 = SegwitV0Precomputed(version: tx.version(), lockTime: tx.lockTime(), inputs: txInputs, outputs: txOutputs)

        let hashesToSign: [Data] = try inputsToSign.map { input in
            let sighashType = input.sighashTypes?.first ?? SighashType.all.rawValue
            return try computeSighash(
                tx: tx,
                txInputs: txInputs,
                txOutputs: txOutputs,
                psbtInputs: psbtInputs,
                inputIndex: input.index,
                sighashType: sighashType,
                segwitV0: segwitV0
            )
        }

        let signatures = try await signDER(hashes: hashesToSign)

        // Insert partial signatures
        let pubKey = try signingPublicKey(for: inputsToSign)
        for (requestInput, derSignature) in zip(inputsToSign, signatures) {
            let sighashType = requestInput.sighashTypes?.first ?? SighashType.all.rawValue
            let sigWithHashType = derSignature + Data([UInt8(truncatingIfNeeded: sighashType)])
            try psbtMaps.setPartialSignature(
                inputIndex: requestInput.index,
                publicKey: pubKey,
                signatureWithSighash: sigWithHashType
            )
        }

        // Finalize PSBT (build finalScriptSig/finalScriptWitness) so dApps don't treat it as "Not finalized".
        let signedBase64 = psbtMaps.serialize().base64EncodedString()
        let bdkSignedPsbt = try Psbt(psbtBase64: signedBase64)
        let finalized = bdkSignedPsbt.finalize()

        guard finalized.couldFinalize else {
            let errorsText = finalized.errors?
                .map { $0.localizedDescription }
                .joined(separator: ", ")
            throw WalletConnectTransactionRequestProcessingError.invalidPayload(
                "PSBT could not be finalized: \(errorsText ?? "unknown error")"
            )
        }

        return finalized.psbt.serialize()
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
        tx: BitcoinDevKit.Transaction,
        txInputs: [BitcoinDevKit.TxIn],
        txOutputs: [BitcoinDevKit.TxOut],
        psbtInputs: [BitcoinDevKit.Input],
        inputIndex: Int,
        sighashType: Int,
        segwitV0: SegwitV0Precomputed
    ) throws -> Data {
        guard txInputs.indices.contains(inputIndex) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Input index out of range: \(inputIndex)")
        }

        guard psbtInputs.indices.contains(inputIndex) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("PSBT input index out of range: \(inputIndex)")
        }

        let utxo = try spendingUtxo(psbtInput: psbtInputs[inputIndex], vout: txInputs[inputIndex].previousOutput.vout)
        let scriptPubKey = utxo.scriptPubkey.toBytes()
        let scriptType = ScriptType(scriptPubKey: scriptPubKey)

        switch scriptType {
        case .p2wpkh:
            let pubKeyHash = scriptPubKey.subdata(in: 2 ..< 22)
            return try Sighash.v0Witness(
                precomputed: segwitV0,
                inputIndex: inputIndex,
                scriptCode: ScriptCode.p2pkh(pubKeyHash: pubKeyHash),
                value: utxo.value.toSat(),
                sighashType: UInt32(sighashType)
            )
        case .p2pkh:
            return try Sighash.legacy(
                version: tx.version(),
                lockTime: tx.lockTime(),
                inputs: txInputs,
                outputs: txOutputs,
                inputIndex: inputIndex,
                scriptCode: scriptPubKey,
                sighashType: UInt32(sighashType)
            )
        case .unsupported(let reason):
            throw WalletConnectTransactionRequestProcessingError.unsupportedMethod("signPsbt \(reason)")
        }
    }

    func spendingUtxo(psbtInput: BitcoinDevKit.Input, vout: UInt32) throws -> BitcoinDevKit.TxOut {
        if let witness = psbtInput.witnessUtxo {
            return witness
        }

        if let nonWitness = psbtInput.nonWitnessUtxo {
            let outputs = nonWitness.output()
            guard outputs.indices.contains(Int(vout)) else {
                throw WalletConnectTransactionRequestProcessingError.invalidPayload("nonWitnessUtxo output index out of range")
            }
            return outputs[Int(vout)]
        }

        throw WalletConnectTransactionRequestProcessingError.invalidPayload("Missing UTXO for input vout=\(vout)")
    }
}

// MARK: - Minimal PSBT key-value updater (BIP174)

private struct PsbtKeyValueMaps {
    private(set) var globalMap: [KV]
    private(set) var inputMaps: [[KV]]
    private(set) var outputMaps: [[KV]]

    init(data: Data, inputCount: Int, outputCount: Int) throws {
        var reader = ByteReader(data)

        let magic = try reader.read(count: 5)
        guard magic == Data([0x70, 0x73, 0x62, 0x74, 0xff]) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Invalid PSBT magic")
        }

        globalMap = try reader.readKVMap()
        inputMaps = try (0 ..< inputCount).map { _ in try reader.readKVMap() }
        outputMaps = try (0 ..< outputCount).map { _ in try reader.readKVMap() }
    }

    mutating func setPartialSignature(inputIndex: Int, publicKey: Data, signatureWithSighash: Data) throws {
        guard inputMaps.indices.contains(inputIndex) else {
            throw WalletConnectTransactionRequestProcessingError.invalidPayload("Input index out of range: \(inputIndex)")
        }

        let key = Data([PsbtKeyType.inputPartialSig]) + publicKey
        let kv = KV(key: key, value: signatureWithSighash)

        var map = inputMaps[inputIndex]
        if let idx = map.firstIndex(where: { $0.key == key }) {
            map[idx] = kv
        } else {
            map.append(kv)
        }
        map.sort(by: { $0.key.lexicographicallyPrecedes($1.key) })
        inputMaps[inputIndex] = map
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
        data.append(0x00)
        return data
    }

    struct KV: Hashable {
        let key: Data
        let value: Data
    }

    enum PsbtKeyType {
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

    mutating func readKVMap() throws -> [PsbtKeyValueMaps.KV] {
        var items: [PsbtKeyValueMaps.KV] = []
        while true {
            let keyLen = try readVarInt()
            if keyLen == 0 {
                break
            }
            let key = try read(count: Int(keyLen))
            let valueLen = try readVarInt()
            let value = try read(count: Int(valueLen))
            items.append(PsbtKeyValueMaps.KV(key: key, value: value))
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

// MARK: - Sighash

private enum SighashType: Int {
    case all = 0x01
}

private enum ScriptType {
    case p2pkh
    case p2wpkh
    case unsupported(String)

    init(scriptPubKey: Data) {
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

private struct SegwitV0Precomputed {
    let version: UInt32
    let lockTime: UInt32
    let inputs: [BitcoinDevKit.TxIn]
    let hashPrevouts: Data
    let hashSequence: Data
    let hashOutputs: Data

    init(version: Int32, lockTime: UInt32, inputs: [BitcoinDevKit.TxIn], outputs: [BitcoinDevKit.TxOut]) {
        self.version = UInt32(bitPattern: version)
        self.lockTime = lockTime
        self.inputs = inputs

        var prevouts = Data()
        prevouts.reserveCapacity(inputs.count * 36)
        for inp in inputs {
            prevouts.append(inp.previousOutput.txid.serialize())
            prevouts.append(inp.previousOutput.vout.littleEndianData)
        }
        hashPrevouts = prevouts.doubleSha256()

        var sequences = Data()
        sequences.reserveCapacity(inputs.count * 4)
        for inp in inputs {
            sequences.append(inp.sequence.littleEndianData)
        }
        hashSequence = sequences.doubleSha256()

        var outs = Data()
        for out in outputs {
            let scriptBytes = out.scriptPubkey.toBytes()
            outs.append(out.value.toSat().littleEndianData)
            outs.append(VarInt.encode(UInt64(scriptBytes.count)))
            outs.append(scriptBytes)
        }
        hashOutputs = outs.doubleSha256()
    }
}

private enum Sighash {
    static func legacy(
        version: Int32,
        lockTime: UInt32,
        inputs: [BitcoinDevKit.TxIn],
        outputs: [BitcoinDevKit.TxOut],
        inputIndex: Int,
        scriptCode: Data,
        sighashType: UInt32
    ) throws -> Data {
        var preimage = Data()
        preimage.append(UInt32(bitPattern: version).littleEndianData)
        preimage.append(VarInt.encode(UInt64(inputs.count)))

        for (idx, inp) in inputs.enumerated() {
            preimage.append(inp.previousOutput.txid.serialize())
            preimage.append(inp.previousOutput.vout.littleEndianData)
            if idx == inputIndex {
                preimage.append(VarInt.encode(UInt64(scriptCode.count)))
                preimage.append(scriptCode)
            } else {
                preimage.append(0x00)
            }
            preimage.append(inp.sequence.littleEndianData)
        }

        preimage.append(VarInt.encode(UInt64(outputs.count)))
        for out in outputs {
            let scriptBytes = out.scriptPubkey.toBytes()
            preimage.append(out.value.toSat().littleEndianData)
            preimage.append(VarInt.encode(UInt64(scriptBytes.count)))
            preimage.append(scriptBytes)
        }

        preimage.append(lockTime.littleEndianData)
        preimage.append(sighashType.littleEndianData)

        return preimage.doubleSha256()
    }

    static func v0Witness(
        precomputed: SegwitV0Precomputed,
        inputIndex: Int,
        scriptCode: Data,
        value: UInt64,
        sighashType: UInt32
    ) throws -> Data {
        var preimage = Data()
        preimage.append(precomputed.version.littleEndianData)
        preimage.append(precomputed.hashPrevouts)
        preimage.append(precomputed.hashSequence)

        let inp = precomputed.inputs[inputIndex]
        preimage.append(inp.previousOutput.txid.serialize())
        preimage.append(inp.previousOutput.vout.littleEndianData)

        preimage.append(VarInt.encode(UInt64(scriptCode.count)))
        preimage.append(scriptCode)

        preimage.append(value.littleEndianData)
        preimage.append(inp.sequence.littleEndianData)

        preimage.append(precomputed.hashOutputs)
        preimage.append(precomputed.lockTime.littleEndianData)
        preimage.append(sighashType.littleEndianData)

        return preimage.doubleSha256()
    }
}

private extension Data {
    func doubleSha256() -> Data {
        sha256().sha256()
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
