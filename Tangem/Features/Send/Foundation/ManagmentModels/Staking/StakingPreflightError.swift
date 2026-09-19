//
//  StakingPreflightError.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum StakingPreflightError: Error {
    /// `feeCurrencyBalance` is `nil` when no balance was loaded to judge against, so nothing could cover the fee.
    case insufficientFundsForFee(feeCurrencyBalance: Decimal?)
}

extension SendStakingableToken {
    /// The failure the staking flow hits before asking for a fee, when the fee currency cannot cover one at all.
    var stakingFeePreflightError: StakingPreflightError? {
        let params = StakingBlockchainParams(blockchain: feeTokenItem.blockchain)
        if params.supportsZeroBalanceOperations { return nil }

        // `spendableValue`, not `loaded`: a cached balance (`.loading`/`.failure` after a refresh hiccup) is still
        // a balance to judge against, and an unfunded account (`.empty(.noAccount)`) counts as zero.
        // Mirrors `CommonTokenFeeProvidersManager.feeCurrencyBalance()`.
        let feeCurrencyBalance = tokenFeeProvidersManager.selectedFeeProvider.balanceFeeTokenState.spendableValue
        if let feeCurrencyBalance, feeCurrencyBalance > .zero { return nil }

        return .insufficientFundsForFee(feeCurrencyBalance: feeCurrencyBalance)
    }
}
