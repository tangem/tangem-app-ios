//
//  SolanaStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Solana staking transactions by parsing the message and checking
/// for the Stake program ID among account keys.
public enum SolanaStakingTransactionValidator {
    /// Stake program ID in base58: Stake11111111111111111111111111111111111111
    static let stakeProgramBytes = Base58.decode("Stake11111111111111111111111111111111111111")

    static let signatureLength = 64
    static let messageHeaderLength = 3
    static let accountKeyLength = 32

    public static func validate(_ unsignedData: String) throws {
        // Hex string must have even length (2 chars per byte)
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let accountKeys = try parseAccountKeys(from: data)

        guard accountKeys.contains(stakeProgramBytes) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Solana",
                details: "Account keys do not contain Stake program ID"
            )
        }
    }
}

// MARK: - Private logic

private extension SolanaStakingTransactionValidator {
    /// Transaction layout: shortvec count + signatures, 3-byte message header, shortvec count + account keys.
    static func parseAccountKeys(from data: Data) throws -> [Data] {
        var reader = ByteReader(data)

        let signaturesCount = try reader.readShortVecLength()
        try reader.skip(signaturesCount * signatureLength)
        try reader.skip(messageHeaderLength)

        let accountKeysCount = try reader.readShortVecLength()
        return try (0 ..< accountKeysCount).map { _ in try reader.read(accountKeyLength) }
    }
}

// MARK: - ByteReader

/// Sequential reader over transaction bytes; throws `emptyOrMalformedData` on out-of-bounds reads.
private struct ByteReader {
    private let data: Data
    private var offset: Int

    init(_ data: Data) {
        self.data = data
        offset = data.startIndex
    }

    mutating func read(_ count: Int) throws -> Data {
        guard offset + count <= data.endIndex else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        defer { offset += count }
        return data[offset ..< offset + count]
    }

    mutating func skip(_ count: Int) throws {
        _ = try read(count)
    }

    /// Decodes a shortvec (compact-u16) length: 7 bits per byte, high bit is a continuation flag.
    mutating func readShortVecLength() throws -> Int {
        var length = 0

        for byteIndex in 0 ..< 3 {
            let byte = try read(1).first ?? 0
            length |= Int(byte & 0x7F) << (byteIndex * 7)

            if byte & 0x80 == 0 {
                return length
            }
        }

        throw StakingTransactionValidationError.emptyOrMalformedData
    }
}
