//
//  PsbtFeeRateLimit+.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension PsbtFeeRateLimit {
    static var usesBdkDogecoinFeeRateLimit: Bool {
        FeatureProvider.isAvailable(.dogecoinPsbtBdkFeeRateLimit)
    }

    init(blockchain: Blockchain) {
        self.init(blockchain: blockchain, usesBdkDogecoinFeeRateLimit: Self.usesBdkDogecoinFeeRateLimit)
    }
}
