//
//  StakingTransactionVerifierFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

enum StakingTransactionVerifierFactory {
    static func make(
        apiKey: String,
        provider: TangemProvider<BlockaidTarget> = .init(configuration: TangemProviderConfiguration())
    ) -> BlockAidStakingVerifier {
        CommonBlockaidAPIService(
            provider: provider,
            credential: BlockaidAPICredential(apiKey: apiKey)
        )
    }
}
