//
//  UserWalletsActionButtonsAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class UserWalletsActionButtonsAvailabilityProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func isActionButtonsAvailable(walletModel: any WalletModel) -> Bool {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == walletModel.userWalletId }) else {
            return false
        }

        if userWalletRepository.models.count > 1 {
            return true
        }

        let balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletModel.config,
            walletModelsPublisher: AccountsFeatureAwareWalletModelsResolver.walletModelsPublisher(for: userWalletModel),
            updatePublisher: userWalletModel.updatePublisher
        )

        return balanceRestrictionFeatureAvailabilityProvider.isActionButtonsAvailable
    }
}
