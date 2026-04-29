//
//  StakingPreflightError.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum StakingPreflightError: Error {
    case insufficientFundsForFee
}

extension SendStakingableToken {
    var canCoverStakingFee: Bool {
        let params = StakingBlockchainParams(blockchain: feeTokenItem.blockchain)
        if params.supportsZeroBalanceOperations { return true }
        guard let balance = tokenFeeProvidersManager.selectedFeeProvider.balanceFeeTokenState.loaded else { return false }
        return balance > .zero
    }
}
