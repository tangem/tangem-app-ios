//
//  CardanoStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import OrderedCollections
import PotentCBOR

/// Validates Cardano staking transactions by checking for certificates or withdrawals in CBOR body.
public enum CardanoStakingTransactionValidator {
    static let certificatesKey: UInt64 = 4
    static let withdrawalsKey: UInt64 = 5

    public static func validate(_ unsignedData: String) throws {
        // Hex string must have even length (2 chars per byte)
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let cbor: CBOR
        do {
            cbor = try CBORSerialization.cbor(from: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        // Transaction is typically an array with body as first element
        let bodyMap = try extractTransactionBody(from: cbor)

        guard hasStakingFields(in: bodyMap) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Cardano",
                details: "Transaction body does not contain certificates (key 4) or withdrawals (key 5)"
            )
        }
    }
}

// MARK: - Private logic

private extension CardanoStakingTransactionValidator {
    /// Extracts the transaction body map from the CBOR structure.
    static func extractTransactionBody(from cbor: CBOR) throws -> OrderedDictionary<CBOR, CBOR> {
        // Transaction format: [body, witnesses, isValid, auxiliaryData]
        // body is a map with various fields including certificates (4) and withdrawals (5)

        guard case .array(let elements) = cbor, let first = elements.first else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        // Remove staking tag if present (tag 258 may be used inside body elements)
        let bodyElement = CBOR.removingTag(CardanoTransactionBody.Constants.stakingTag, from: first)

        guard case .map(let mapValue) = bodyElement else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        return mapValue
    }

    /// Checks if the transaction body contains staking-related fields.
    static func hasStakingFields(in bodyMap: OrderedDictionary<CBOR, CBOR>) -> Bool {
        let certificatesKey = CBOR.unsignedInt(Self.certificatesKey)
        let withdrawalsKey = CBOR.unsignedInt(Self.withdrawalsKey)

        let hasCertificates = bodyMap[certificatesKey] != nil
        let hasWithdrawals = bodyMap[withdrawalsKey] != nil

        return hasCertificates || hasWithdrawals
    }
}
