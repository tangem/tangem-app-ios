//
//  TonConnectBoc.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TonSwift

/// Helpers for the base64 "raw one-cell BoC" fields dApps send (`payload`, `stateInit`, `cell`).
///
/// A dApp-supplied BoC is untrusted input. `TonSwift`'s deserialiser assumes well-formed data and can
/// trap (out-of-range index, integer conversion) on a corrupted header, so every BoC is first run through
/// `preflight`, a strict structural walk that only accepts what the deserialiser can safely consume.
enum TonConnectBoc {
    /// Upper bound on a serialised BoC accepted from a dApp. Real payloads are a few hundred bytes;
    /// the limit only protects the parser from pathological input.
    static let maxSerializedByteCount = 64 * 1024

    /// Upper bound on the number of cells in one BoC.
    static let maxCellCount = 4096

    /// Upper bound on the depth of the cell tree. Real payloads are a handful of levels deep (a jetton
    /// transfer is 3, a DEX swap about 6); TonSwift serialises and hashes trees recursively, and a chain a few
    /// hundred cells deep overflows a secondary thread's stack — observed with a 513-cell chain under the
    /// test runner. Refusing anything deeper than 64 keeps that path unreachable from a dApp.
    static let maxDepth = 64

    /// Decodes a base64 (standard or url-safe alphabet) BoC that must contain exactly one root cell.
    static func singleRootCell(base64: String, field: String) throws -> Cell {
        guard let data = decodeBase64(base64) else {
            throw TonConnectError.badRequest("\(field) is not valid base64")
        }

        guard data.count <= maxSerializedByteCount else {
            throw TonConnectError.badRequest("\(field) exceeds \(maxSerializedByteCount) bytes")
        }

        do {
            try preflight(data)
        } catch let error as PreflightError {
            throw TonConnectError.badRequest("\(field) is not a valid BoC: \(error.rawValue)")
        }

        let roots: [Cell]
        do {
            roots = try Cell.fromBoc(src: data)
        } catch {
            throw TonConnectError.badRequest("\(field) is not a valid BoC")
        }

        guard roots.count == 1, let root = roots.first else {
            throw TonConnectError.badRequest("\(field) must contain exactly one root cell")
        }

        return root
    }

    /// Serialises a cell the way dApps expect it back: standard base64 BoC with CRC32C.
    static func base64(_ cell: Cell) throws -> String {
        try cell.toBoc(idx: false, crc32: true).base64EncodedString()
    }

    // MARK: - Structural preflight

    enum PreflightError: String, Error, Equatable {
        case truncated = "truncated"
        case badMagic = "unsupported magic"
        case badFlags = "reserved flag bits set"
        case badSizeBytes = "invalid ref size"
        case badOffsetBytes = "invalid offset size"
        case badCellCount = "invalid cell count"
        case notSingleRoot = "root count is not 1"
        case absentCells = "absent cells are not supported"
        case badRootIndex = "root index out of range"
        case badCellDataSize = "cell data size mismatch"
        case tooManyRefs = "cell has more than 4 refs"
        case badLevel = "non-zero level is not supported"
        case badRefIndex = "ref index is not a forward reference"
        case unsupportedExotic = "exotic cells are not supported"
        case tooDeep = "cell tree is too deep"
        case trailingBytes = "trailing bytes after BoC"
    }

    /// Walks the `serialized_boc#b5ee9c72` layout and validates every length and index before
    /// `TonSwift` sees the bytes. Only what a dApp legitimately sends is accepted: a single root,
    /// no absent cells, ordinary (non-exotic) level-0 cells and forward-only references.
    static func preflight(_ data: Data) throws {
        var cursor = ByteCursor(data)

        guard try cursor.readUInt(byteCount: 4) == 0xB5EE_9C72 else {
            throw PreflightError.badMagic
        }

        let flags = try cursor.readByte()
        let hasIndex = flags & 0x80 != 0
        let hasCRC32C = flags & 0x40 != 0
        guard flags & 0x18 == 0 else { throw PreflightError.badFlags } // reserved flags must be 0
        let refByteCount = Int(flags & 0x07)
        guard (1 ... 4).contains(refByteCount) else { throw PreflightError.badSizeBytes }

        let offsetByteCount = Int(try cursor.readByte())
        guard (1 ... 8).contains(offsetByteCount) else { throw PreflightError.badOffsetBytes }

        let cellCount = try cursor.readUInt(byteCount: refByteCount)
        let rootCount = try cursor.readUInt(byteCount: refByteCount)
        let absentCount = try cursor.readUInt(byteCount: refByteCount)
        let totalCellSize = try cursor.readUInt(byteCount: offsetByteCount)

        guard cellCount >= 1, cellCount <= UInt64(maxCellCount) else { throw PreflightError.badCellCount }
        guard rootCount == 1 else { throw PreflightError.notSingleRoot }
        guard absentCount == 0 else { throw PreflightError.absentCells }

        let rootIndex = try cursor.readUInt(byteCount: refByteCount)
        guard rootIndex < cellCount else { throw PreflightError.badRootIndex }

        if hasIndex {
            try cursor.skip(Int(cellCount) * offsetByteCount)
        }

        guard totalCellSize <= UInt64(cursor.remaining) else { throw PreflightError.truncated }
        let cellDataEnd = cursor.position + Int(totalCellSize)

        // Refs only point forward, so the depth of every cell follows from its refs in a single reverse pass.
        var refsOf = [[Int]](repeating: [], count: Int(cellCount))

        for index in 0 ..< Int(cellCount) {
            let d1 = try cursor.readByte()
            let d2 = try cursor.readByte()

            let refCount = Int(d1 & 0x07)
            let isExotic = d1 & 0x08 != 0
            let level = d1 >> 5
            guard refCount <= 4 else { throw PreflightError.tooManyRefs }
            guard level == 0 else { throw PreflightError.badLevel }

            // Exotic cells (pruned branches, Merkle proofs/updates, library cells) have no place in an
            // outgoing message body or a deploy StateInit sent by a dApp, and TonSwift's handling of them
            // is not robust against hostile input — reject them outright.
            guard !isExotic else { throw PreflightError.unsupportedExotic }

            try cursor.skip((Int(d2) + 1) / 2)

            for _ in 0 ..< refCount {
                let ref = try cursor.readUInt(byteCount: refByteCount)
                guard ref > UInt64(index), ref < cellCount else { throw PreflightError.badRefIndex }
                refsOf[index].append(Int(ref))
            }

            guard cursor.position <= cellDataEnd else { throw PreflightError.badCellDataSize }
        }

        guard cursor.position == cellDataEnd else { throw PreflightError.badCellDataSize }

        var depth = [Int](repeating: 0, count: Int(cellCount))
        for index in stride(from: Int(cellCount) - 1, through: 0, by: -1) {
            depth[index] = (refsOf[index].map { depth[$0] }.max() ?? -1) + 1
            guard depth[index] <= maxDepth else { throw PreflightError.tooDeep }
        }

        if hasCRC32C {
            try cursor.skip(4)
        }

        guard cursor.remaining == 0 else { throw PreflightError.trailingBytes }
    }

    private struct ByteCursor {
        private let data: Data
        private(set) var position: Int

        init(_ data: Data) {
            self.data = data
            position = data.startIndex
        }

        var remaining: Int { data.endIndex - position }

        mutating func readByte() throws -> UInt8 {
            guard remaining >= 1 else { throw PreflightError.truncated }
            defer { position += 1 }
            return data[position]
        }

        func peekByte() throws -> UInt8 {
            guard remaining >= 1 else { throw PreflightError.truncated }
            return data[position]
        }

        mutating func readUInt(byteCount: Int) throws -> UInt64 {
            guard byteCount <= 8, remaining >= byteCount else { throw PreflightError.truncated }
            var value: UInt64 = 0
            for _ in 0 ..< byteCount {
                value = value << 8 | UInt64(data[position])
                position += 1
            }
            return value
        }

        mutating func skip(_ count: Int) throws {
            guard count >= 0, remaining >= count else { throw PreflightError.truncated }
            position += count
        }
    }

    private static func decodeBase64(_ string: String) -> Data? {
        var normalized = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = normalized.count % 4
        if remainder != 0 {
            normalized += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: normalized)
    }
}
