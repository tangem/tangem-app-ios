//
//  LendingRateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol LendingRateProvider {
    func currentApy() async throws -> Decimal
}

struct CommonLendingRateProvider: LendingRateProvider {
    @Injected(\.yieldModuleNetworkManager) private var networkManager: YieldModuleNetworkManager

    func currentApy() async throws -> Decimal {
        guard let chainId = LendingOnAave.blockchain.chainId else {
            throw YieldModuleError.unsupportedBlockchain
        }

        let info = try await networkManager.fetchYieldTokenInfo(
            tokenContractAddress: LendingOnAave.wrappedNativeAddress,
            chainId: chainId
        )

        return info.apy
    }
}
