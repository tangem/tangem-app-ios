//
//  PsbtKeyValueMap.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - PSBT internals (BIP174)

/// Lightweight PSBT key-value maps reader/writer.
///
/// Note: This type is intentionally minimal and supports only the operations we need for signing flow
/// (e.g. inserting `partial_sigs`). It doesn't try to be a full BIP174 implementation.
/// https://learnmeabitcoin.com/technical/transaction/psbt/
struct PsbtKeyValueMap {
    private(set) var globalMap: [KV]
    private(set) var inputMaps: [[KV]]
    private(set) var outputMaps: [[KV]]

    init(data: Data, inputCount: Int, outputCount: Int) throws {
        var reader = ByteReader(data)
        let magic = try reader.read(count: 5)
        guard magic == Const.magicBytes else {
            throw BitcoinError.invalidPsbt("Invalid PSBT magic")
        }

        globalMap = try reader.readKVMap()
        inputMaps = try (0 ..< inputCount).map { _ in try reader.readKVMap() }
        outputMaps = try (0 ..< outputCount).map { _ in try reader.readKVMap() }
    }

    mutating func setPartialSignature(inputIndex: Int, publicKey: Data, signatureWithSighash: Data) throws {
        try setInputKV(inputIndex: inputIndex, key: Data([KeyType.inputPartialSig]) + publicKey, value: signatureWithSighash)
    }

    func serialize() -> Data {
        var data = Const.magicBytes
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
            throw BitcoinError.inputIndexOutOfRange(inputIndex)
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
            data.append(VariantIntEncoder.encode(UInt64(kv.key.count)))
            data.append(kv.key)
            data.append(VariantIntEncoder.encode(UInt64(kv.value.count)))
            data.append(kv.value)
        }
        data.append(0x00)
        return data
    }
}

extension PsbtKeyValueMap {
    enum KeyType {
        static let globalUnsignedTx: UInt8 = 0x00
        static let inputPartialSig: UInt8 = 0x02
    }

    enum Const {
        static let magicBytes = Data([0x70, 0x73, 0x62, 0x74, 0xff])
    }

    struct KV: Hashable {
        let key: Data
        let value: Data
    }
}

// MARK: - Low-level readers/writers

private struct ByteReader {
    private let data: Data
    private var offset: Int = 0

    init(_ data: Data) {
        self.data = data
    }

    mutating func read(count: Int) throws -> Data {
        guard offset + count <= data.count else {
            throw BitcoinError.invalidPsbt("Unexpected EOF")
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

    /// Reads a Bitcoin/PSBT CompactSize varint (aka "varint") from the underlying byte stream.
    ///
    /// Encoding:
    /// - `0x00 ... 0xFC`: the value is the prefix byte itself (1 byte total)
    /// - `0xFD`: followed by `UInt16` little-endian (3 bytes total)
    /// - `0xFE`: followed by `UInt32` little-endian (5 bytes total)
    /// - `0xFF`: followed by `UInt64` little-endian (9 bytes total)
    ///
    /// - Returns: Decoded unsigned integer.
    /// - Throws: `BitcoinError.invalidPsbt("Unexpected EOF")` if there aren't enough bytes to read.
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
            throw BitcoinError.invalidPsbt("Invalid varint")
        }
    }

    mutating func readVarBytes() throws -> Data {
        let len = Int(try readVarInt())
        return try read(count: len)
    }

    mutating func readKVMap() throws -> [PsbtKeyValueMap.KV] {
        var items: [PsbtKeyValueMap.KV] = []
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
