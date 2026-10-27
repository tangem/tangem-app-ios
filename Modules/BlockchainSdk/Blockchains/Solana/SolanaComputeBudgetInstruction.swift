//
//  SolanaComputeBudgetInstruction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SolanaComputeBudgetInstruction {
    static let programId = "ComputeBudget111111111111111111111111111111"

    static func instructions(computeUnitLimit: UInt32?, computeUnitPrice: UInt64?) -> [SolanaRawInstruction] {
        [
            computeUnitLimit.map(setComputeUnitLimit(_:)),
            computeUnitPrice.map(setComputeUnitPrice(microLamports:)),
        ].compactMap { $0 }
    }

    static func setComputeUnitLimit(_ units: UInt32) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: programId,
            accounts: [],
            data: Data([Discriminator.setComputeUnitLimit]) + littleEndianBytes(units)
        )
    }

    static func setComputeUnitPrice(microLamports: UInt64) -> SolanaRawInstruction {
        SolanaRawInstruction(
            programId: programId,
            accounts: [],
            data: Data([Discriminator.setComputeUnitPrice]) + littleEndianBytes(microLamports)
        )
    }

    static func computeUnitLimit(fromData data: [UInt8]) -> UInt32? {
        guard data.count == 5, data[0] == Discriminator.setComputeUnitLimit else {
            return nil
        }

        return data[1...].reversed().reduce(0) { $0 << 8 | UInt32($1) }
    }

    private static func littleEndianBytes<Value: FixedWidthInteger>(_ value: Value) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    private enum Discriminator {
        static let setComputeUnitLimit: UInt8 = 2
        static let setComputeUnitPrice: UInt8 = 3
    }
}
