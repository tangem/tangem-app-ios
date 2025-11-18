//
//  LazyUserWalletModelProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct LazyUserWalletModelProvider {
    let userWalletId: UserWalletId
    private let repository: UserWalletRepository

    init(userWalletId: UserWalletId, repository: UserWalletRepository) {
        self.userWalletId = userWalletId
        self.repository = repository
    }

    func getModel() -> UserWalletModel? {
        guard let userWalletModel = repository.models[userWalletId] else {
            assertionFailure("Model for userWalletId \(userWalletId) not found in repository")
            return nil
        }

        return userWalletModel
    }
}
