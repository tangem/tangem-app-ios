//
//  HDWalletScript.swift
//  BlockchainSdkClips
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum ScriptType: UInt8 {
    /// Pay to pubkey hash (aka pay to address)
    case p2pkh = 1
    /// Pay to pubkey
    case p2pk = 2
    /// Pay to script hash
    case p2sh = 3
    /// Pay to witness pubkey hash
    case p2wpkh = 4
    /// Pay to witness script hash
    case p2wsh = 5
}

public class HDWalletScript {
    // An array of Data objects (pushing data) or UInt8 objects (containing opcodes)
    private var chunks: [ScriptChunk]

    // Cached serialized representations for -data and -string methods.
    private var dataCache: Data?
    private var stringCache: String?

    public var data: Data {
        // When we calculate data from scratch, it's important to respect actual offsets in the chunks as they may have been copied or shifted in subScript* methods.
        if let cache = dataCache {
            return cache
        }
        dataCache = chunks.reduce(Data()) { $0 + $1.chunkData }
        return dataCache!
    }

    public var string: String {
        if let cache = stringCache {
            return cache
        }
        stringCache = chunks.map { $0.string }.joined(separator: " ")
        return stringCache!
    }

    public var hex: String {
        return data.hex
    }

    public func toP2SH() -> HDWalletScript {
        return try! HDWalletScript()
            .append(.OP_HASH160)
            .appendData(RIPEMD160.hash(message: data.sha256()))
            .append(.OP_EQUAL)
    }

    // Multisignature script attribute.
    // If multisig script is not detected, this is nil
    public typealias MultisigVariables = (nSigRequired: UInt, publickeys: [HDPublicKey])
    public var multisigRequirements: MultisigVariables?

    // MARK: - Initializers
    
    public init() {
        self.chunks = [ScriptChunk]()
    }

    public init(chunks: [ScriptChunk]) {
        self.chunks = chunks
    }

    public convenience init?(data: Data) {
        // It's important to keep around original data to correctly identify the size of the script for BTC_MAX_SCRIPT_SIZE check
        // and to correctly calculate hash for the signature because in BitcoinQT scripts are not re-serialized/canonicalized.
        do {
            let chunks = try HDWalletScript.parseData(data)
            self.init(chunks: chunks)
        } catch let error {
            print(error)
            return nil
        }
    }

    public convenience init(hex: String) {
        self.init(data: Data(hex: hex))!
    }

    public convenience init?(address: HDAddress) {
        self.init()
        switch address.type {
        case .pubkeyHash:
            // OP_DUP OP_HASH160 <hash> OP_EQUALVERIFY OP_CHECKSIG
            do {
                try self.append(.OP_DUP)
                    .append(.OP_HASH160)
                    .appendData(address.data)
                    .append(.OP_EQUALVERIFY)
                    .append(.OP_CHECKSIG)
            } catch {
                return nil
            }
        case .scriptHash:
            // OP_HASH160 <hash> OP_EQUAL
            do {
                try self.append(.OP_HASH160)
                    .appendData(address.data)
                    .append(.OP_EQUAL)
            } catch {
                return nil
            }
        default:
            return nil
        }
    }

    // OP_<M> <pubkey1> ... <pubkeyN> OP_<N> OP_CHECKMULTISIG
    public convenience init?(publicKeys: [HDPublicKey], signaturesRequired: UInt) {
        // First make sure the arguments make sense.
        // We need at least one signature
        guard signaturesRequired > 0 else {
            return nil
        }

        // And we cannot have more signatures than available pubkeys.
        guard publicKeys.count >= signaturesRequired else {
            return nil
        }

        // Both M and N should map to OP_<1..16>
        let mOpcode: OpCode = OpCodeFactory.opcode(for: Int(signaturesRequired))
        let nOpcode: OpCode = OpCodeFactory.opcode(for: publicKeys.count)

        guard mOpcode != .OP_INVALIDOPCODE else {
            return nil
        }
        guard nOpcode != .OP_INVALIDOPCODE else {
            return nil
        }
        do {
            self.init()
            try append(mOpcode)
            for pubkey in publicKeys {
                try appendData(pubkey.data)
            }
            try append(nOpcode)
            try append(.OP_CHECKMULTISIG)
            multisigRequirements = (signaturesRequired, publicKeys)
        } catch {
            return nil
        }
    }
    
    // MARK: -

    private static func parseData(_ data: Data) throws -> [ScriptChunk] {
        guard !data.isEmpty else {
            return [ScriptChunk]()
        }

        var chunks = [ScriptChunk]()

        var i: Int = 0
        let count: Int = data.count

        while i < count {
            // Exit if failed to parse
            let chunk = try ScriptChunkHelper.parseChunk(from: data, offset: i)
            chunks.append(chunk)
            i += chunk.range.count
        }
        return chunks
    }
    
    public var scriptType: ScriptType {
        if isPayToPublicKeyHashScript {
            return .p2pkh
        }
        if isPayToScriptHashScript {
            return .p2sh
        }
        return .p2pk
    }

    public var isStandard: Bool {
        return isPayToPublicKeyHashScript
            || isPayToScriptHashScript
            || isPublicKeyScript
            || isStandardMultisignatureScript
    }

    public var isPublicKeyScript: Bool {
        guard chunks.count == 2 else {
            return false
        }
        guard let pushdata = pushedData(at: 0) else {
            return false
        }
        return pushdata.count > 1 && opcode(at: 1) == OpCode.OP_CHECKSIG
    }

    public var isPayToPublicKeyHashScript: Bool {
        guard chunks.count == 5 else {
            return false
        }
        guard let dataChunk = chunk(at: 2) as? DataChunk else {
            return false
        }
        return opcode(at: 0) == OpCode.OP_DUP
            && opcode(at: 1) == OpCode.OP_HASH160
            && dataChunk.range.count == 21
            && opcode(at: 3) == OpCode.OP_EQUALVERIFY
            && opcode(at: 4) == OpCode.OP_CHECKSIG
    }

    public var isPayToScriptHashScript: Bool {
        guard chunks.count == 3 else {
            return false
        }
        return opcode(at: 0) == OpCode.OP_HASH160
            && pushedData(at: 1)?.count == 20 // this is enough to match the exact byte template, any other encoding will be larger.
            && opcode(at: 2) == OpCode.OP_EQUAL
    }
    
    public var isSentToMultisig: Bool {
        if chunks.count < 4 { return false }
        let chunk = chunks[chunks.count - 1]
        
        // Must end in OP_CHECKMULTISIG[VERIFY].
        if !(chunk.opCode.isOpCode) { return false }
        if !(chunk.opCode == OpCode.OP_CHECKMULTISIG || chunk.opCode == OpCode.OP_CHECKMULTISIGVERIFY) { return false }
        
        // Second to last chunk must be an OP_N opcode and there should be that many data chunks (keys).
        let m = chunks[chunks.count - 2]
        
        if !(m.opCode.isOpCode) { return false }
        do {
            let numKeys = try decodeFromOpN(opcode: m.opCode)
            if numKeys < 1 || chunks.count != 3 + Int(numKeys) { return false }
            
            for i in 1..<(chunks.count - 2) {
                let chunk = chunks[i]
                // Second check is needed because of OpCode implementation. It's not supported custom opcodes like data lenght that is lower than PUSHDATA1
                // Ex. for bitcoin multisig addresses it will be the length of the compressed public key (33)
                if chunk.opCode.isOpCode && chunk.opcodeValue >= OpCode.OP_PUSHDATA1.value {
                    return false
                }
            }
            if try decodeFromOpN(opcode: chunks[0].opCode) < 1 {
                return false
            }
        } catch {
            return false
        }
        return true
    }

    // Returns true if the script ends with P2SH check.
    // Not used in CoreBitcoin. Similar code is used in bitcoin-ruby. I don't know if we'll ever need it.
    public var endsWithPayToScriptHash: Bool {
        guard chunks.count >= 3 else {
            return false
        }
        return opcode(at: -3) == OpCode.OP_HASH160
            && pushedData(at: -2)?.count == 20
            && opcode(at: -1) == OpCode.OP_EQUAL
    }

    public var isStandardMultisignatureScript: Bool {
        guard isMultisignatureScript else {
            return false
        }
        guard let multisigPublicKeys = multisigRequirements?.publickeys else {
            return false
        }
        return multisigPublicKeys.count <= 3
    }

    public var isMultisignatureScript: Bool {
        guard let requirements = multisigRequirements else {
            return false
        }
        if requirements.nSigRequired == 0 {
            detectMultisigScript()
        }

        return requirements.nSigRequired > 0
    }

    public var isStandardOpReturnScript: Bool {
        guard chunks.count == 2 else {
            return false
        }
        return opcode(at: 0) == .OP_RETURN
            && pushedData(at: 1) != nil
    }

    public func standardOpReturnData() -> Data? {
        guard isStandardOpReturnScript else {
            return nil
        }
        return pushedData(at: 1)
    }

    // If typical multisig tx is detected, sets requirements:
    private func detectMultisigScript() {
        // multisig script must have at least 4 ops ("OP_1 <pubkey> OP_1 OP_CHECKMULTISIG")
        guard chunks.count >= 4 else {
            return
        }

        // The last op is multisig check.
        guard opcode(at: -1) == OpCode.OP_CHECKMULTISIG else {
            return
        }

        let mOpcode: OpCode = opcode(at: 0)
        let nOpcode: OpCode = opcode(at: -2)

        let m: Int = OpCodeFactory.smallInteger(from: mOpcode)
        let n: Int = OpCodeFactory.smallInteger(from: nOpcode)

        guard m > 0 && m != Int.max else {
            return
        }
        guard n > 0 && n != Int.max && n >= m else {
            return
        }

        // We must have correct number of pubkeys in the script. 3 extra ops: OP_<M>, OP_<N> and OP_CHECKMULTISIG
        guard chunks.count == 3 + n else {
            return
        }

        var pubkeys: [HDPublicKey] = []
        for i in 0...n {
            guard
                let data = pushedData(at: i),
                let pubkey = HDPublicKey(privateKey: data, coin: .bitcoin)
            else { return }
            
            // [REDACTED_TODO_COMMENT]
            pubkeys.append(pubkey)
        }

        // Now we extracted all pubkeys and verified the numbers.
        multisigRequirements = (UInt(m), pubkeys)
    }

    // Include both PUSHDATA ops and OP_0..OP_16 literals.
    public var isDataOnly: Bool {
        return !chunks.contains { $0.opcodeValue > OpCode.OP_16 }
    }

    public var scriptChunks: [ScriptChunk] {
        return chunks
    }

    // MARK: - Modification
    public func invalidateSerialization() {
        dataCache = nil
        stringCache = nil
        multisigRequirements = nil
    }

    private func update(with updatedData: Data) throws {
        let updatedChunks = try HDWalletScript.parseData(updatedData)
        chunks = updatedChunks
        invalidateSerialization()
    }

    @discardableResult
    public func append(_ opcode: OpCode) throws -> HDWalletScript {
        let invalidOpCodes: [OpCode] = [.OP_PUSHDATA1,
                                                .OP_PUSHDATA2,
                                                .OP_PUSHDATA4,
                                                .OP_INVALIDOPCODE]
        guard !invalidOpCodes.contains(where: { $0 == opcode }) else {
            throw ScriptError.error("\(opcode.name) cannot be executed alone.")
        }
        var updatedData: Data = data
        updatedData += opcode
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func appendData(_ newData: Data) throws -> HDWalletScript {
        guard !newData.isEmpty else {
            throw ScriptError.error("Data is empty.")
        }

        guard let addedScriptData = ScriptChunkHelper.scriptData(for: newData, preferredLengthEncoding: -1) else {
            throw ScriptError.error("Parse data to pushdata failed.")
        }
        var updatedData: Data = data
        updatedData += addedScriptData
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func appendScript(_ otherScript: HDWalletScript) throws -> HDWalletScript {
        guard !otherScript.data.isEmpty else {
            throw ScriptError.error("Script is empty.")
        }

        var updatedData: Data = self.data
        updatedData += otherScript.data
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func deleteOccurrences(of data: Data) throws -> HDWalletScript {
        guard !data.isEmpty else {
            return self
        }

        let updatedData = chunks.filter { ($0 as? DataChunk)?.pushedData != data }.reduce(Data()) { $0 + $1.chunkData }
        try update(with: updatedData)
        return self
    }

    @discardableResult
    public func deleteOccurrences(of opcode: OpCode) throws -> HDWalletScript {
        let updatedData = chunks.filter { $0.opCode != opcode }.reduce(Data()) { $0 + $1.chunkData }
        try update(with: updatedData)
        return self
    }

    public func subScript(from index: Int) throws -> HDWalletScript {
        let subScript: HDWalletScript = HDWalletScript()
        for chunk in chunks[index..<chunks.count] {
            try subScript.appendData(chunk.chunkData)
        }
        return subScript
    }

    public func subScript(to index: Int) throws -> HDWalletScript {
        let subScript: HDWalletScript = HDWalletScript()
        for chunk in chunks[0..<index] {
            try subScript.appendData(chunk.chunkData)
        }
        return subScript
    }

    // MARK: - Utility methods
    // Raise exception if index is out of bounds
    public func chunk(at index: Int) -> ScriptChunk {
        return chunks[index < 0 ? chunks.count + index : index]
    }

    // Returns an opcode in a chunk.
    // If the chunk is data, not an opcode, returns OP_INVALIDOPCODE
    // Raises exception if index is out of bounds.
    public func opcode(at index: Int) -> OpCode {
        let chunk = self.chunk(at: index)
        // If the chunk is not actually an opcode, return invalid opcode.
        guard chunk is OpcodeChunk else {
            return .OP_INVALIDOPCODE
        }
        return chunk.opCode
    }

    // Returns Data in a chunk.
    // If chunk is actually an opcode, returns nil.
    // Raises exception if index is out of bounds.
    public func pushedData(at index: Int) -> Data? {
        let chunk = self.chunk(at: index)
        return (chunk as? DataChunk)?.pushedData
    }
    
    private func decodeFromOpN(opcode: OpCode) throws -> UInt8 {
        guard
            opcode == OpCode.OP_0 ||
                opcode == OpCode.OP_1NEGATE ||
                (OpCode.OP_1 <= opcode && opcode <= OpCode.OP_16)
        else { throw ScriptError.error("decodeFromOpN called on non OP_N opcode") }
        if opcode == OpCode.OP_0 {
            return 0
        } else if opcode == OpCode.OP_1NEGATE {
            return UInt8(bitPattern: -1)
        } else {
            return opcode.value + 1 - OpCode.OP_1.value
        }
        
    }
}

extension HDWalletScript {
    // Standard Transaction to Bitcoin address (pay-to-pubkey-hash)
    // scriptPubKey: OP_DUP OP_HASH160 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
    public static func buildPublicKeyHashOut(pubKeyHash: Data) -> Data {
        let tmp: Data = Data() + OpCode.OP_DUP + OpCode.OP_HASH160 + UInt8(pubKeyHash.count) + pubKeyHash
        return tmp + OpCode.OP_EQUALVERIFY + OpCode.OP_CHECKSIG
    }

    public static func buildPublicKeyUnlockingScript(signature: Data, pubkey: HDPublicKey, hashType: SighashType) -> Data {
        var data: Data = Data([UInt8(signature.count + 1)]) + signature + UInt8(hashType)
        data += VarInt(pubkey.data.count).serialized()
        data += pubkey.data
        return data
    }

    public static func isPublicKeyHashOut(_ script: Data) -> Bool {
        return script.count == 25 &&
            script[0] == OpCode.OP_DUP && script[1] == OpCode.OP_HASH160 && script[2] == 20 &&
            script[23] == OpCode.OP_EQUALVERIFY && script[24] == OpCode.OP_CHECKSIG
    }

    public static func getPublicKeyHash(from script: Data) -> Data {
        return script[3..<23]
    }
}

extension HDWalletScript: CustomStringConvertible {
    public var description: String {
        return string
    }
}

enum ScriptError: Error {
    case error(String)
}
