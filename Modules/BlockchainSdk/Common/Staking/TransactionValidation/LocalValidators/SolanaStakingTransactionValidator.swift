//
//  SolanaStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Solana staking transactions by checking for Stake program in account keys.
public enum SolanaStakingTransactionValidator {
    static let stakeProgramId = "Stake11111111111111111111111111111111111111"

    private enum Constants {
        static let signatureLength = 64
        static let headerLength = 3
        static let pubkeyLength = 32
    }

    public static func validate(_ unsignedData: String) throws {
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let accountKeys = try extractAccountKeys(from: data)

        guard accountKeys.contains(Self.stakeProgramId) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Solana",
                details: "Transaction does not contain Stake program (\(Self.stakeProgramId))"
            )
        }
    }

    /// Extracts account keys from a Solana transaction binary data.
    ///
    /// Transaction format:
    /// 1. First byte = signature count
    /// 2. signature_count × 64 bytes = signatures (or placeholders)
    /// 3. 3 bytes = message header
    /// 4. 1 byte = number of account keys
    /// 5. account_count × 32 bytes = account keys (pubkeys)
    private static func extractAccountKeys(from data: Data) throws -> Set<String> {
        var offset = 0

        // 1. Read signature count and skip signatures
        guard offset < data.count else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let signatureCount = Int(data[offset])
        offset += 1
        offset += signatureCount * Constants.signatureLength

        // 2. Skip 3-byte message header
        offset += Constants.headerLength

        guard offset < data.count else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        // 3. Read account count (1 byte)
        let accountCount = Int(data[offset])
        offset += 1

        // 4. Read account keys
        var accountKeys = Set<String>()
        for _ in 0 ..< accountCount {
            guard offset + Constants.pubkeyLength <= data.count else {
                throw StakingTransactionValidationError.emptyOrMalformedData
            }

            let pubkeyData = data[offset ..< offset + Constants.pubkeyLength]
            let pubkey = Base58.encode(pubkeyData)
            accountKeys.insert(pubkey)
            offset += Constants.pubkeyLength
        }

        return accountKeys
    }
}
