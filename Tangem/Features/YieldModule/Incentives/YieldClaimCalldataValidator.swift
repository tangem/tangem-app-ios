//
//  YieldClaimCalldataValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// Gates card signing on fresh claim calldata; any failure means no signature prompt.
struct YieldClaimCalldataValidator {
    struct ValidatedClaim: Equatable {
        let to: String
        let data: Data
    }

    struct Context {
        let chainId: Int
        let userAddress: String
        /// The user's module address established independently of the claim-calldata response.
        let moduleAddress: String
        /// Lowercased addresses of reward tokens whose current destination is confirmed supported.
        let supportedRewardTokens: Set<String>
    }

    enum Failure: Error, Equatable {
        case nothingClaimable
        case notRecommended
        case incompleteCalldata
        case malformedCalldata
        case contextMismatch
        case destinationMismatch
        case malformedRewardList
        /// The backend calldata is never filtered locally — a token without confirmed support fails the whole claim.
        case unsupportedRewardToken
    }

    func validate(_ calldata: YieldClaimCalldata, context: Context) throws(Failure) -> ValidatedClaim {
        guard calldata.hasClaimable else {
            throw .nothingClaimable
        }

        guard calldata.claimRecommended else {
            throw .notRecommended
        }

        guard let moduleAddress = calldata.moduleAddress, let to = calldata.to, let dataHex = calldata.data else {
            throw .incompleteCalldata
        }

        guard calldata.chainId == context.chainId,
              calldata.userAddress.caseInsensitiveEquals(to: context.userAddress) else {
            throw .contextMismatch
        }

        guard to.caseInsensitiveEquals(to: moduleAddress),
              to.caseInsensitiveEquals(to: context.moduleAddress) else {
            throw .destinationMismatch
        }

        guard !calldata.rewardTokens.isEmpty,
              calldata.rewardTokens.count == calldata.cumulativeAmounts.count else {
            throw .malformedRewardList
        }

        guard calldata.rewardTokens.allSatisfy({ context.supportedRewardTokens.contains($0.lowercased()) }) else {
            throw .unsupportedRewardToken
        }

        guard let data = Self.claimData(fromHex: dataHex) else {
            throw .malformedCalldata
        }

        return ValidatedClaim(to: to, data: data)
    }

    /// `Data(hexString:)` answers with empty data for anything it cannot parse, so only a byte count matching
    /// the hex digits proves the payload survived decoding.
    private static func claimData(fromHex hex: String) -> Data? {
        let digits = hex.removeHexPrefix()
        let data = Data(hexString: hex)

        guard !data.isEmpty, data.count * 2 == digits.count else {
            return nil
        }

        return data
    }
}
