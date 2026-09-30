//
//  TonConnectBocPreflightTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

/// `TonSwift.Cell.fromBoc` traps on several malformed inputs (a ref index past the cell table, exotic
/// cells). These tests pin that every such input is turned into a thrown `badRequest` before TonSwift runs.
@Suite(.tags(.tonConnect))
struct TonConnectBocPreflightTests {
    /// Root with a 32-bit payload and two child cells (one shared twice), serialised without index, with CRC.
    private func makeTree() throws -> Cell {
        let leaf = try Builder().store(uint: 0xAB, bits: 8).endCell()
        let branch = try Builder().store(uint: 1, bits: 8).store(ref: leaf).endCell()
        return try Builder().store(uint: 0xDEAD_BEEF, bits: 32).store(ref: branch).store(ref: leaf).endCell()
    }

    @Test
    func acceptsWellFormedBocsWithAndWithoutCRCAndIndex() throws {
        let root = try makeTree()

        for (idx, crc) in [(false, true), (false, false), (true, true), (true, false)] {
            let data = try root.toBoc(idx: idx, crc32: crc)
            #expect(throws: Never.self) { try TonConnectBoc.preflight(data) }
            #expect(try TonConnectBoc.singleRootCell(base64: data.base64EncodedString(), field: "payload") == root)
        }
    }

    @Test
    func acceptsEmptyCell() throws {
        // Canonical empty-cell BoC as produced by `@ton/core` (`beginCell().endCell()`); TonSwift itself
        // cannot serialise an empty cell, so the bytes are pinned here.
        let empty = try TonConnectBoc.singleRootCell(base64: "te6ccgEBAQEAAgAAAA==", field: "p")
        #expect(empty.bits.length == 0)
        #expect(empty.refs.isEmpty)
        #expect(empty == (try Builder().endCell()))
    }

    @Test
    func rejectsExoticLeafCellsBeforeTonSwiftParsesThem() throws {
        let data = try makeTree().toBoc(idx: false, crc32: false)
        // Flip the exotic bit (0x08) on the leaf cell's d1 (cell #2 starts at 11 + 8 + 4 = 23).
        var exoticLeaf = data
        exoticLeaf[exoticLeaf.startIndex + 23] |= 0x08

        #expect(throws: TonConnectBoc.PreflightError.unsupportedExotic) { try TonConnectBoc.preflight(exoticLeaf) }
    }

    @Test
    func rejectsTruncatedAndForeignInput() throws {
        let data = try makeTree().toBoc(idx: false, crc32: false)

        #expect(throws: TonConnectBoc.PreflightError.truncated) { try TonConnectBoc.preflight(Data()) }
        #expect(throws: TonConnectBoc.PreflightError.truncated) { try TonConnectBoc.preflight(data.prefix(5)) }
        #expect(throws: TonConnectBoc.PreflightError.truncated) { try TonConnectBoc.preflight(data.dropLast()) }
        #expect(throws: TonConnectBoc.PreflightError.badMagic) { try TonConnectBoc.preflight(Data(repeating: 0, count: 16)) }
        #expect(throws: TonConnectBoc.PreflightError.trailingBytes) { try TonConnectBoc.preflight(data + Data([0])) }
    }

    @Test
    func rejectsCorruptedHeaders() throws {
        let data = try makeTree().toBoc(idx: false, crc32: false)
        // Layout for this tree: magic(4) flags(1: size=1) offBytes(1) cells(1) roots(1) absent(1) totalSize(1) rootIdx(1) cells…
        func mutated(_ offset: Int, _ value: UInt8) -> Data {
            var copy = data
            copy[copy.startIndex + offset] = value
            return copy
        }

        #expect(throws: TonConnectBoc.PreflightError.badFlags) { try TonConnectBoc.preflight(mutated(4, data[4] | 0x10)) }
        #expect(throws: TonConnectBoc.PreflightError.badSizeBytes) { try TonConnectBoc.preflight(mutated(4, data[4] & ~0x07)) }
        #expect(throws: TonConnectBoc.PreflightError.badSizeBytes) { try TonConnectBoc.preflight(mutated(4, data[4] | 0x07)) }
        #expect(throws: TonConnectBoc.PreflightError.badOffsetBytes) { try TonConnectBoc.preflight(mutated(5, 0)) }
        #expect(throws: TonConnectBoc.PreflightError.badOffsetBytes) { try TonConnectBoc.preflight(mutated(5, 9)) }
        #expect(throws: TonConnectBoc.PreflightError.badCellCount) { try TonConnectBoc.preflight(mutated(6, 0)) }
        #expect(throws: TonConnectBoc.PreflightError.notSingleRoot) { try TonConnectBoc.preflight(mutated(7, 2)) }
        #expect(throws: TonConnectBoc.PreflightError.notSingleRoot) { try TonConnectBoc.preflight(mutated(7, 0)) }
        #expect(throws: TonConnectBoc.PreflightError.absentCells) { try TonConnectBoc.preflight(mutated(8, 1)) }
        #expect(throws: TonConnectBoc.PreflightError.badRootIndex) { try TonConnectBoc.preflight(mutated(10, 3)) }
        // Shrinking the declared cell-data size leaves the real cells running past it.
        #expect(throws: TonConnectBoc.PreflightError.badCellDataSize) { try TonConnectBoc.preflight(mutated(9, data[9] - 1)) }
    }

    @Test
    func rejectsCorruptedCells() throws {
        let data = try makeTree().toBoc(idx: false, crc32: false)
        let firstCell = 11 // d1 of the root cell
        func mutated(_ offset: Int, _ value: UInt8) -> Data {
            var copy = data
            copy[copy.startIndex + offset] = value
            return copy
        }

        // Root: d1 = 2 refs, d2 = 8 (4 bytes), data(4), ref(1), ref(1)
        #expect(throws: TonConnectBoc.PreflightError.tooManyRefs) { try TonConnectBoc.preflight(mutated(firstCell, 0x05)) }
        #expect(throws: TonConnectBoc.PreflightError.badLevel) { try TonConnectBoc.preflight(mutated(firstCell, 0x22)) }
        #expect(throws: TonConnectBoc.PreflightError.unsupportedExotic) { try TonConnectBoc.preflight(mutated(firstCell, 0x0A)) }

        let firstRef = firstCell + 2 + 4
        #expect(throws: TonConnectBoc.PreflightError.badRefIndex) { try TonConnectBoc.preflight(mutated(firstRef, 0)) } // self-reference
        #expect(throws: TonConnectBoc.PreflightError.badRefIndex) { try TonConnectBoc.preflight(mutated(firstRef, 200)) } // out of table
    }

    @Test
    func outOfRangeRefIndexBecomesBadRequestInsteadOfTrap() throws {
        let data = try makeTree().toBoc(idx: false, crc32: false)
        var corrupted = data
        corrupted[corrupted.startIndex + 17] = 200

        #expect(throws: TonConnectError.badRequest("payload is not a valid BoC: ref index is not a forward reference")) {
            try TonConnectBoc.singleRootCell(base64: corrupted.base64EncodedString(), field: "payload")
        }
    }
}
