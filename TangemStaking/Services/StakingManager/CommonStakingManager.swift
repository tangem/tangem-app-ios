//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingManager {
    private let wallet: StakingWallet
    private let repository: StakingRepository
    private let provider: StakingAPIProvider
    private let logger: Logger

    init(
        wallet: StakingWallet,
        repository: StakingRepository,
        provider: StakingAPIProvider,
        logger: Logger
    ) {
        self.wallet = wallet
        self.repository = repository
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingManager: StakingManager {
    func getYield() throws -> YieldInfo {
        guard let yield = repository.getYield(item: wallet.stakingTokenItem) else {
            throw StakingManagerError.notFound
        }

        return yield
    }

    func getFee(amount: Decimal, validator: String) async throws {
        let action = try await provider.enterAction(
            amount: amount,
            address: wallet.defaultAddress,
            validator: validator,
            integrationId: getYield().id
        )
    }

    func getTransaction() async throws {
        // TBD: [REDACTED_INFO]
    }
}

public enum StakingManagerError: Error {
    case notFound
}
