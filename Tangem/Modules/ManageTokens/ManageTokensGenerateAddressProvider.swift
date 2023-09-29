//
//  ManageTokensGenerateAddressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ManageTokensGenerateAddressProvider {
    // MARK: - Private Properties

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Private Implementation

    func performDeriveIfNeeded(with userWalletId: UserWalletId, _ completion: (() -> Void)? = nil) {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            completion?()
            return
        }

        userWalletModel.userTokensManager.deriveIfNeeded(completion: { _ in
            completion?()
        })
    }
}
