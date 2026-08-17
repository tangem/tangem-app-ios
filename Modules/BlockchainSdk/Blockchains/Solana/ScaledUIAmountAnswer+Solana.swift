//
//  ScaledUIAmountAnswer+Solana.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension ScaledUIAmount.Answer {
    /// Reads what a provider's `getAccountInfo` response says about the mint's scaling.
    ///
    /// Anything short of a parsed answer is `unknown` rather than `noScaling`: a response the mint account is missing
    /// from, a declared extension without a state, a multiplier that does not parse. Saying `noScaling` for those
    /// would skip the division on a mint that does declare a multiplier, which is what inflates the signed transfer.
    init(accountInfo: SolanaScaledUiAmountDTO.GetAccountInfoResult, transactionDate: Date) {
        guard let extensions = accountInfo.value?.data?.parsed?.info?.extensions else {
            self = .unknown
            return
        }

        guard let config = extensions.first(where: { $0.extension == Constants.scaledUiAmountConfig }) else {
            // A provider whose parser predates an extension serializes a placeholder in place of its name, spelled
            // `unparseableExtension` or `unparsableExtension` depending on the version. The scaled UI amount config
            // may be the one hidden behind it, so its absence proves nothing here.
            let hidesExtension = extensions.contains {
                $0.extension.lowercased().hasPrefix(Constants.unnamedExtensionPrefix)
            }

            self = hidesExtension ? .unknown : .noScaling
            return
        }

        guard let state = config.state else {
            self = .unknown
            return
        }

        let transactionTimestamp = Int64(transactionDate.timeIntervalSince1970)
        let multiplierString: String?

        if let effectiveTimestamp = state.newMultiplierEffectiveTimestamp,
           transactionTimestamp >= effectiveTimestamp {
            multiplierString = state.newMultiplier
        } else {
            multiplierString = state.multiplier
        }

        guard let multiplier = Decimal(stringValue: multiplierString) else {
            self = .unknown
            return
        }

        self = .multiplier(multiplier)
    }
}

private extension ScaledUIAmount.Answer {
    enum Constants {
        static let scaledUiAmountConfig = "scaledUiAmountConfig"
        static let unnamedExtensionPrefix = "unpars"
    }
}
