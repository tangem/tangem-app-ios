//
//  YieldModuleBlockchainAvailability.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct YieldModuleBlockchainAvailability {
    private let isMerklIncentivesAvailable: Bool

    init(isMerklIncentivesAvailable: Bool = FeatureProvider.isAvailable(.merklIncentives)) {
        self.isMerklIncentivesAvailable = isMerklIncentivesAvailable
    }

    func isAvailable(on blockchain: Blockchain) -> Bool {
        isAvailable(chainId: blockchain.chainId)
    }

    func isAvailable(chainId: Int?) -> Bool {
        guard chainId == Self.monadChainId else {
            return true
        }

        return isMerklIncentivesAvailable
    }

    private static let monadChainId = Blockchain.monad(testnet: false).chainId
}
